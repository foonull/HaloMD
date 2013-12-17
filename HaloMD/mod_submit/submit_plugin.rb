#Created by nil

require 'rubygems'
require 'json'
require 'pathname'
require 'fileutils'
require 'digest/md5'

def print_and_execute_command(command)
	puts command
	`#{command}`
	if $?.exitstatus != 0
		puts "Exit status is a failure from last command.."
		exit 3
	end
end

OUTPUT_PATH = "md_submit_output"
MOD_JSON_NAME = "mods.json"
JSON_PATH = (Pathname.new(OUTPUT_PATH) + MOD_JSON_NAME).to_s

if ARGV.length < 1
	puts "Usage: ruby #{$0} <plugin_path>"
	exit 1
end
plugin_path = ARGV[0]

unless File.exists?(plugin_path)
	puts "ERROR: Failed to locate plugin at #{plugin_path}"
	exit 2
end

plugin_name = File.basename(plugin_path, '.*')

if File.exists? OUTPUT_PATH
	puts "Removing #{OUTPUT_PATH}..."
	FileUtils.rm_rf(OUTPUT_PATH)
end

FileUtils.mkdir(OUTPUT_PATH)

info_plist_path = File.join(plugin_path, "Contents/Info.plist")
puts "Converting #{info_plist_path} to json..."
print_and_execute_command("plutil -convert json \"#{info_plist_path}\" -o \"#{OUTPUT_PATH}/plugin.json\"")

info_entries = JSON.parse(IO.read(File.join(OUTPUT_PATH, 'plugin.json')))

puts "Fetching mods/plugin list..."
print_and_execute_command("curl http://halomd.macgamingmods.com/mods/mods.json -o #{JSON_PATH}")
puts "Downloaded #{JSON_PATH}"

mod_entries = JSON.parse(IO.read(JSON_PATH))
if not mod_entries
	puts "ERROR: Failed to properly parse #{JSON_PATH}"
	exit 4
end

#temporary
unless mod_entries.key? 'Plug-ins'
	mod_entries['Plug-ins'] = []
end

previous_versions = mod_entries['Plug-ins'].select {|entry| entry['name'] == plugin_name}
if previous_versions.count > 0
	puts "Found #{previous_versions.count} previous version(s) of #{plugin_name}:"
	previous_items = previous_versions.map {|entry| ["Name: #{entry['name']}", "Build: #{entry['build']}", "Version: #{entry['version']}", "Description: #{entry['description']}"].join("\n")}
	puts previous_items.join("\n\n")
else
	puts "No previous versions of #{plugin_name} were found."
end

puts "\n"

unless info_entries.key?  'CFBundleShortVersionString'
	puts "ERROR: Failed to find CFBundleShortVersionString entry"
	exit 5
end

plugin_version = info_entries['CFBundleShortVersionString']

unless info_entries.key? 'MDGlobalPlugin'
	puts "ERROR: Failed to find MDGlobalPlugin entry"
	exit 6
end

global_plugin = info_entries['MDGlobalPlugin']

unless info_entries.key? 'MDMapPlugin'
	puts "ERROR: Failed to find MDMapPlugin entry"
	exit 7
end

map_plugin = info_entries['MDMapPlugin']

unless map_plugin or global_plugin
	puts "ERROR: Plug-in isn't set for map or global mode!"
	exit 8
end

puts "What is this new plugin's description?"
puts "Leave blank to use #{plugin_name} #{previous_versions[0]['version']}'s description" if previous_versions.count > 0

plugin_description = $stdin.gets.chomp
if plugin_description.length == 0 and previous_versions.count > 0
	plugin_description = previous_versions[0]['description']
end

unless info_entries.key? 'CFBundleVersion'
	puts "ERROR: Failed to find CFBundleVersion entry"
	exit 9
end

new_build_number = info_entries['CFBundleVersion'].to_i

if new_build_number <= 0
	puts "ERROR: Build number is <= 0"
	exit 10
end

if previous_versions.count > 0
	previous_build_number = previous_versions[0]['build'].to_i
	if new_build_number <= previous_build_number
		puts "ERROR: New build number #{new_build_number} is <= previous build number #{previous_build_number}"
		exit 11
	end
end

puts "Creating new plug-in...\n\n"
puts "Name: #{plugin_name}"
puts "Build: #{new_build_number}"
puts "Version: #{plugin_version}"
puts "Description: #{plugin_description}"
puts "Plug-in Type: Global" if global_plugin
puts "Plug-in Type: Map" if map_plugin
puts "\n"

new_plugin_entry = {'name' => plugin_name, 'description' => plugin_description, 'version' => plugin_version, 'build' => new_build_number, 'MDGlobalPlugin' => global_plugin, 'MDMapPlugin' => map_plugin}

new_plugin_entries = [new_plugin_entry] + mod_entries['Plug-ins']

puts "Removing old json file... (#{JSON_PATH})"
FileUtils.rm(JSON_PATH) if File.exists? JSON_PATH

puts "Writing new json file... (#{JSON_PATH})"
File.open(JSON_PATH, "w") do |json_file|
	json_file.write(JSON.pretty_generate({"Mods" => mod_entries['Mods'], "Plug-ins" => new_plugin_entries})) #pretty print
end

puts "Writing gzipped json file... (#{JSON_PATH}.gz)"
print_and_execute_command("gzip < \"#{JSON_PATH}\" > \"#{JSON_PATH}.gz\"")

puts "Converting json to plist..."
print_and_execute_command("plutil -convert xml1 \"#{JSON_PATH}\" -o \"#{OUTPUT_PATH}/mods.plist\"")

puts "Zipping plugin..."
plugin_zip_path = File.join(Dir.pwd, OUTPUT_PATH, "#{plugin_name}.zip")
Dir.chdir(File.dirname(plugin_path)) do
	print_and_execute_command("zip -r \"#{plugin_zip_path}\" \"#{File.basename(plugin_path)}\"")
end
