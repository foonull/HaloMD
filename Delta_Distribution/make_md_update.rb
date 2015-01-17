#!/usr/bin/ruby

require 'pathname'
require 'digest/md5'
require 'fileutils'
require 'json'

OUTPUT_DIRECTORY = "mdtempoutput"

def print_usage
	puts "Usage: <private_key> <new_MD_app> <old_MD_app1> <old_MD_app2> ..."
	puts "Old apps should be listed with the most recent versions first"
end

def execute_command(command)
	`#{command}`
	if $?.exitstatus != 0
		puts "Exit status is a failure from last command.."
		exit 3
	end
end

def print_and_execute_command(command)
	puts command
	execute_command(command)
end

def build_and_short_version_from_app(app_path)
	info_path = Pathname.new(app_path) + "Contents/Info.plist"
	temp_path = Pathname.new(OUTPUT_DIRECTORY) + "tempinfo.json"
	execute_command("plutil -convert json \"#{info_path}\" -o \"#{temp_path}\"")
	jsonContents = JSON.parse(IO.read(temp_path))
	FileUtils.rm(temp_path)
	return [jsonContents["CFBundleVersion"].to_i, jsonContents["CFBundleShortVersionString"]]
end

def sign_file(file_path, private_key_path)
	temp_path = Pathname.new(OUTPUT_DIRECTORY) + "sig"
	print_and_execute_command("./sign_update.sh \"#{file_path}\" \"#{private_key_path}\" > \"#{temp_path}\"")
	signature = IO.read(temp_path).strip()
	FileUtils.rm(temp_path)
	return signature
end

def make_old_app_patch(new_app_path, old_app_path, new_build_number, old_build_number, private_key_path)
	patch_name = "#{old_build_number}-to-#{new_build_number}.delta"
	patch_path = Pathname.new(OUTPUT_DIRECTORY) + patch_name
	print_and_execute_command("./BinaryDelta create \"#{old_app_path}\" \"#{new_app_path}\" \"#{patch_path}\"")
	return [patch_name, sign_file(patch_path, private_key_path), File.stat(patch_path).size]
end

if not File.exist? "BinaryDelta" or not File.directory? "Sparkle.framework"
	puts "Error: cannot find BinaryDelta or Sparkle.framework"
	exit(1)
end

if ARGV.length < 2
	print_usage()
	exit(1)
end

private_key_path = ARGV[0]
unless File.exist? private_key_path
	puts "ERROR: private key at path #{private_key_path} does not exist"
	print_usage()
	exit(1)
end

##Just a little app/map validation
halomd_path = ARGV[1]
halomd_maps_path = Pathname.new(halomd_path) + "Contents/Resources/Data/DoNotTouchOrModify/Maps/"
stock_maps = ["bloodgulch", "crossing", "barrier", "bitmaps", "ui", "sounds"]
map_hashes = ["dde1ec328ed9527542e8be94d988b4e0", "8881f2749b1c0396581ec8a12256f01b", "30d76559112bbe58655319d551f6aa98", "3aa76ba21068930d25f57abd48a36b5a", "8cdd73b429308fe5abd3a74627d0618b", "45e064c46685ddcb4da717b3978662a4"]
stock_map_paths = stock_maps.map {|map| halomd_maps_path + "#{map}.map"}

stock_map_paths.each_with_index do |path, index|
	unless File.exists? path
		puts "ERROR: Failed to locate stock map at #{path}"
		exit(1)
	end

	hash = Digest::MD5.hexdigest(IO.read(path))
	unless hash == map_hashes[index]
		puts "ERROR: #{path} md5 hash is not #{hash}"
		exit(1)
	end
end
##

if File.exists? OUTPUT_DIRECTORY
	FileUtils.rm_rf(OUTPUT_DIRECTORY)
end
Dir.mkdir OUTPUT_DIRECTORY

build_and_short_version = build_and_short_version_from_app(halomd_path)
old_build_and_short_versons = []

old_app_paths = ARGV[2..-1]
last_old_app_build = 0
old_app_paths.each do |path|
	unless File.exists? path
		print_usage()
		puts "ERROR: Failed to locate old MD app at #{path}"
		exit(1)
	end

	old_build_and_short_versons << build_and_short_version_from_app(path)

	if old_build_and_short_versons[-1][0] >= build_and_short_version[0]
		puts "ERROR: Old app build #{old_build_and_short_versons[-1][0]} is >= new build #{build_and_short_version[0]}"
		exit(1)
	end

	if old_build_and_short_versons[-1][0] <= last_old_app_build
		puts "ERROR: Old app paths are not passed in order from newest to oldest!"
		exit(1)
	end
	last_old_app_build = old_build_and_short_versons[-1][0]
end

md_output_directory = Pathname.new(OUTPUT_DIRECTORY) + "HaloMD"
Dir.mkdir md_output_directory

how_to_run_path = "How to Run.rtfd"

print_and_execute_command("cp -r \"#{how_to_run_path}\" \"#{md_output_directory}\"")
print_and_execute_command("cp -r \"#{halomd_path}\" \"#{md_output_directory}\"")
puts "Creating zip..."
current_directory =  Dir.pwd
Dir.chdir(OUTPUT_DIRECTORY)

zip_name = "HaloMDnew.zip"
zip_path = Pathname.new(OUTPUT_DIRECTORY) + zip_name

execute_command("zip -r #{zip_name} HaloMD")
Dir.chdir(current_directory)

zip_signature = sign_file(zip_path, private_key_path)
zip_size = File.stat(zip_path).size

FileUtils.rm_rf(md_output_directory)

delta_items = []
old_app_paths.each_with_index do |old_path, index|
	patch_name, signature, size = make_old_app_patch(halomd_path, old_path, build_and_short_version[0], old_build_and_short_versons[index][0], private_key_path)
	delta_item = '<enclosure url="http://halomd.macgamingmods.com/' +  patch_name + '" ' +
		'sparkle:version="' + build_and_short_version[0].to_s + '" ' +
		'sparkle:shortVersionString="' + build_and_short_version[1] + '" ' +
		'sparkle:deltaFrom="' + old_build_and_short_versons[index][0].to_s + '" ' +
		'length="' + size.to_s + '" ' +
		'type="application/octet-stream" ' +
		'sparkle:dsaSignature="' + signature + '" />'
	delta_items << delta_item
end

appcast_template_contents = IO.read("appcast_template.xml")
new_contents = appcast_template_contents.gsub("$DELTA_ITEMS", delta_items.join("\n")).gsub("$MD_HUMAN_VERSION", build_and_short_version[1].to_s).gsub("$MD_BUILD", build_and_short_version[0].to_s).gsub("$MD_ZIP_LENGTH", zip_size.to_s).gsub("$MD_CODE_SIG", zip_signature).gsub("$MD_PUB_DATE", Time.now.strftime("%a, %-d %b %Y"))

IO.write(Pathname.new(OUTPUT_DIRECTORY) + "halomd_appcast.xml", new_contents)

puts "Wrote files to #{OUTPUT_DIRECTORY}. Verify that the app inside the zip opens and works (sometimes os x can be wonky..). These files will be uploaded to the top level directory of the server. Make sure to upload #{zip_name} first, move and rename the old stable version into old_releases/ appropriately, and then rename the uploaded zip to HaloMD.zip. Then update and upload the releasenotes.html with new info, upload the the delta patch file(s). Finally, upload/replace the appcast as the last step."
