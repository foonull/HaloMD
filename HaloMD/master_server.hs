-- Copyright (c) 2015, Null <foo.null@yahoo.com>
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
-- 
-- Redistributions of source code must retain the above copyright notice, this
-- list of conditions and the following disclaimer.
-- 
-- Redistributions in binary form must reproduce the above copyright notice, this
-- list of conditions and the following disclaimer in the documentation and/or
-- other materials provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
-- ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- A Halo Master Server lobby server alternative to gamespy, which will require its own client implementation too
-- Port 27900 on UDP and 29920 on TCP will need to be open on the server running this program
-- To compile: ghc master_server.hs -O -o master_server
-- MGM's centos server needs to pass -user-package-db due to ghc not picking the user's packages database, or something strange..

import Control.Monad
import Control.Concurrent
import Control.Concurrent.STM.TChan
import GHC.Conc.Sync
import Data.List
import Network.Socket hiding (send, sendTo, recv, recvFrom)
import Network.Socket.ByteString
import qualified Data.ByteString.Char8 as C8
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import Data.Time.Clock
import System.IO.Error
import Control.Monad.Trans.Maybe
import Data.Binary
import Data.Int

data Game = Game {hostName :: HostName, portNumber :: PortNumber, lastUpdated :: UTCTime}
type Games = [Game]

instance Eq Game where
	Game hostName1 portNumber1 _ == Game hostName2 portNumber2 _ =
		(hostName1 == hostName2) && (portNumber1 == portNumber2)

instance Show Game where -- for debugging purposes
	show (Game hostName portNumber utcTime) = intercalate ":" [hostName, show portNumber] ++ " " ++ (show $ utctDayTime utcTime)

data GameState = GameStateAlive {forceCreation :: Bool} | GameStateDead deriving (Show)
data GameUpdate = GameUpdate Game GameState deriving (Show)
type GameUpdates = [GameUpdate]

type GameUpdateChannel = TChan GameUpdate

-- Only accept 1.09 and 1.10 game servers
validGameVersions :: [String]
validGameVersions = ["01.00.09.0620", "01.00.10.0621"]

-- Time it takes to unlist a game server if it's not responding
gameTimeoutTime :: NominalDiffTime
gameTimeoutTime = 60

-- Finds numeric host name and port number from sockAddr
-- Because no lookups are done, this should be nonblocking
hostNameAndPortFromSockAddr :: SockAddr -> IO (HostName, PortNumber)
hostNameAndPortFromSockAddr sockAddr = do
	(Just hostName, _) <- getNameInfo [NI_NUMERICHOST] True False sockAddr
	let portNumber = case sockAddr of
		(SockAddrInet portNumber _) -> portNumber
		(SockAddrInet6 portNumber _ _ _) -> portNumber
	return (hostName, portNumber)

-- Read all new game updates from a given channel
readGameUpdates :: GameUpdateChannel -> IO (GameUpdates)
readGameUpdates channel = do
	isEmpty <- atomically $ isEmptyTChan channel
	if isEmpty then return []
	else do
		gameUpdate <- atomically $ readTChan channel
		newUpdates <- readGameUpdates channel
		return $ gameUpdate : newUpdates

-- Apply game updates to given list of games to obtain an updated list
applyGameUpdates :: Games -> GameUpdates -> Games
applyGameUpdates initialGames gameUpdates = foldl applyUpdate initialGames gameUpdates
	where applyUpdate games (GameUpdate game gameState) =
		case gameState of
			GameStateAlive forceCreation ->
				case find (== game) games of
					Just foundGame ->
						if diffUTCTime (lastUpdated game) (lastUpdated foundGame) > 0 then
							game : delete foundGame games
						else games
					Nothing -> if forceCreation then game : games else games
			GameStateDead -> delete game games

-- readGameUpdates followed by applyGameUpdates
readAndApplyGameUpdates :: GameUpdateChannel -> Games -> IO (Games)
readAndApplyGameUpdates channel games = readGameUpdates channel >>= return . (applyGameUpdates games)

-- Handle sending the client a list of IP addresses plus their own IP with a magical notation at the end
handleLobbyServer :: GameUpdateChannel -> Games -> Socket -> IO ()
handleLobbyServer readChannel games lobbySocket = do
	(clientSocket, sockAddr) <- accept lobbySocket
	(host, _) <- hostNameAndPortFromSockAddr sockAddr

	newGames <- readAndApplyGameUpdates readChannel games

	let lobbyAddresses = (map (\game -> intercalate ":" [hostName game, (show . portNumber) game]) newGames) ++ [host ++ magicClientTag]
		where magicClientTag = ":49149:3425"
	tryIOError $ sendAll clientSocket $ C8.pack $ intercalate "\n" lobbyAddresses
	sClose clientSocket

	handleLobbyServer readChannel newGames lobbySocket

-- Finds a game value corresponding to targetKey in game info array from a heartbeat mesage
findGameValue :: [String] -> String -> Maybe String
findGameValue [] _ = Nothing
findGameValue [_] _ = Nothing
findGameValue (key:value:xs) targetKey
	| (key == targetKey) = Just value
	| otherwise = findGameValue xs targetKey

-- Retrieves a game state corresponding to provided game state mode, and if it's open playing, also from the provided game version
gameStateFromHeartbeatMode :: Maybe String -> String -> Maybe GameState
gameStateFromHeartbeatMode gameVersion mode
	 | (mode == openPlayingMode) =
	 	gameVersion >>= (\version -> 
			if version `elem` validGameVersions then
				Just GameStateAlive {forceCreation = True}
			else Nothing)
	| (mode == exitingMode) = Just GameStateDead
	| otherwise = Nothing
	where
		(openPlayingMode, exitingMode) = ("openplaying", "exiting")

-- Retrieves a game state corresponding to provided opcode, and if it's a heartbeat message, also from the game info array
gameStateFromOpcode:: [String] -> Int8 -> Maybe GameState
gameStateFromOpcode gameInfo opcode
	| (opcode == heartbeatOpcode) = gameMode >>= gameStateFromHeartbeatMode gameVersion
	| (opcode == keepAliveOpcode) = Just GameStateAlive {forceCreation = False}
	| otherwise = Nothing
	where
		(heartbeatOpcode, keepAliveOpcode)  = (0x3, 0x8)
		[gameMode, gameVersion] = map (findGameValue gameInfo) ["gamemode", "gamever"]

-- Handles heartbeat and keep alive messages from game servers
handleHeartbeatServer :: GameUpdateChannel -> GameUpdateChannel -> Games -> Socket -> IO ()
handleHeartbeatServer readChannel writeChannel games heartbeatSocket = do
	(byteString, sockAddr) <- recvFrom heartbeatSocket 1024
	(host, port) <- hostNameAndPortFromSockAddr sockAddr
	newGames <- readAndApplyGameUpdates readChannel games
	currentTime <- getCurrentTime
	
	let
		updateGame = atomically . writeTChan writeChannel . GameUpdate (Game host port currentTime)
		gameInfo = map C8.unpack (B.split 0x0 (B.drop 5 byteString)) -- skip 1-byte opcode and 4-byte handshake key
		opcodeValue = 
			if B.length byteString > 0 then
				(Just . decode . BL.fromChunks) [(B.take 1 byteString)]
			else Nothing
	
	maybe (return ()) updateGame (opcodeValue >>= gameStateFromOpcode gameInfo)
	
	handleHeartbeatServer readChannel writeChannel newGames heartbeatSocket

-- Manages forced game timeouts and mediates game updates between all the listening servers
handleMainLoop :: [GameUpdateChannel] -> [GameUpdateChannel] -> Games -> IO ()
handleMainLoop readChannels writeChannels games = do
	readChannelUpdates <- mapM readGameUpdates readChannels

	let readUpdates = join readChannelUpdates
	let currentGames = applyGameUpdates games readUpdates

	currentTime <- getCurrentTime

	let (aliveGames, deadGames) = partition ((< gameTimeoutTime) . diffUTCTime currentTime . lastUpdated) currentGames
	let deadGameUpdates = map (flip GameUpdate GameStateDead) deadGames

	let updateChannel channel = mapM (atomically . writeTChan channel) (readUpdates ++ deadGameUpdates)
	mapM updateChannel writeChannels
	
	threadDelay 1000000
	handleMainLoop readChannels writeChannels aliveGames

-- Creates, sets for reuse, and binds a socket from the given addrInfo
createAndConfigureSocket :: AddrInfo -> MaybeT IO Socket
createAndConfigureSocket addrInfo =
	makeSocketT >>= makeReuseT >>= makeBindT
	where
		mapAction f = fmap (either (const Nothing) f) . tryIOError
		makeSocketT =  MaybeT . mapAction Just $ socket (addrFamily addrInfo) (addrSocketType addrInfo) (addrProtocol addrInfo)
		makeOperationT serverSocket action = MaybeT . (mapAction . const . Just) serverSocket $ action
		makeReuseT serverSocket = makeOperationT serverSocket $ setSocketOption serverSocket ReuseAddr 1
		makeBindT serverSocket = makeOperationT serverSocket $ bindSocket serverSocket (addrAddress addrInfo)

-- Make a server socket for given type and port
makeServerSocket :: SocketType -> PortNumber -> IO (Maybe Socket)
makeServerSocket socketType portNumber = do
	-- If we ever want to support IPv6 (unlikely), we can change addrFamily to AF_UNSPEC.. but that'd require the lobby spec to change
	let hints = defaultHints {addrFlags = [AI_PASSIVE, AI_NUMERICSERV], addrFamily = AF_INET, addrSocketType = socketType}
	addressInfosHandle <- tryIOError $ getAddrInfo (Just hints) Nothing (Just $ show portNumber)
	-- Find the first addrInfo we can create a socket successfully from. Apparently mplus on MaybeT stops after the first Just
	either (return . const Nothing) (runMaybeT . msum . (map createAndConfigureSocket)) addressInfosHandle

main = do
	[mainToLobbyChannel, heatbeatToMainChannel, mainToHeartbeatChannel] <- replicateM 3 $ atomically newTChan

	let spawnSocketThread socketType portNumber name action =
		forkIO $ makeServerSocket socketType portNumber >>= maybe (error $ "Error: Failed to create " ++ name) action

	spawnSocketThread Datagram 27900 "Heartbeat Server" $ handleHeartbeatServer mainToHeartbeatChannel heatbeatToMainChannel []
	spawnSocketThread Stream 29920 "Lobby Server" (\sock -> listen sock backlog >> handleLobbyServer mainToLobbyChannel [] sock)

	handleMainLoop [heatbeatToMainChannel] [mainToLobbyChannel, mainToHeartbeatChannel] []
	
	where backlog = 10
