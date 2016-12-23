#Created by nil

require 'rubygems'
require 'json'
require 'pathname'
require 'fileutils'
require 'digest/md5'

def short_name(identifier)
	identifier[0 .. identifier.rindex("_")-1]
end

def build_number(identifier)
	identifier[identifier.rindex("_")+1 .. -1].to_i
end

def print_and_execute_command(command)
	puts command
	`#{command}`
	if $?.exitstatus != 0
		puts "Exit status is a failure from last command.."
		exit 3
	end
end

MODS_URL = "https://halomd.macgamingmods.com/mods/mods.json.gz"

OUTPUT_PATH = "md_submit_output"
MOD_JSON_NAME = "mods.json"
JSON_PATH = (Pathname.new(OUTPUT_PATH) + MOD_JSON_NAME).to_s

DEFAULT_NUMBER_OF_PATCHES = 3

if ARGV.length < 2
	puts "Usage: ruby #{$0} <mod_path> <HaloMD_path>"
	exit 1
end

mod_path = ARGV[0]
halomd_path = ARGV[1]
max_number_of_patches = ARGV.length > 2 ? ARGV[2].to_i : DEFAULT_NUMBER_OF_PATCHES

unless File.exists?(mod_path)
	puts "ERROR: Failed to locate mod at #{mod_path}"
	exit 2
end

mod_identifier = File.basename(mod_path, '.*')

halomd_maps_path = Pathname.new(halomd_path) + "Contents/Resources/Data/DoNotTouchOrModify/Maps/"
stock_maps = ["bloodgulch", "crossing", "barrier"]
stock_map_paths = stock_maps.map {|map| halomd_maps_path + "#{map}.map"}

stock_map_paths.each do |path|
	unless File.exists? path
		puts "ERROR: Failed to locate stock map at #{path}"
		exit 7
	end
end

if File.exists? OUTPUT_PATH
	puts "Removing #{OUTPUT_PATH}..."
	FileUtils.rm_rf(OUTPUT_PATH)
end

FileUtils.mkdir(OUTPUT_PATH)

puts "Fetching mods list..."
print_and_execute_command("curl #{MODS_URL} | zcat > \"#{JSON_PATH}\"")
puts "Downloaded #{JSON_PATH}"

mod_entries = JSON.parse(IO.read(JSON_PATH))
if not mod_entries
	puts "ERROR: Failed to properly parse #{JSON_PATH}"
	exit 4
end

if mod_entries['Mods'].select {|entry| entry['identifier'] == mod_identifier}.count > 0
	puts "ERROR: Mod identifier #{mod_identifier} already exists. Please choose another identifier."
	exit 8
end

puts "What mod name would you like to use:"
mod_name = $stdin.gets.chomp
puts "\n"

if mod_entries['Mods'].select {|entry| entry['name'] != mod_name and short_name(entry['identifier']) == short_name(mod_identifier)} .count > 0
	puts "ERROR: Short name #{short_name(mod_identifier)} is already in use by a different mod!"
	exit 9
end

previous_versions = mod_entries['Mods'].select {|entry| entry['name'] == mod_name}
if previous_versions.count > 0
	puts "Found #{previous_versions.count} previous version(s) of #{mod_name}:"
	previous_items = previous_versions.map {|entry| ["Identifier: #{entry['identifier']}", "Version: #{entry['human_version']}", "Description: #{entry['description']}", "Plug-ins: #{entry['plug-ins'] == nil ? '' : entry['plug-ins'].join(', ')}"].join("\n")}
	puts previous_items.join("\n\n")
else
	puts "No previous versions of #{mod_name} were found."
end

puts "\n"

puts "What is this new mod's version?"
mod_version = $stdin.gets.chomp

if previous_versions.select {|entry| entry['human_version'] == mod_version}.count > 0
	puts "ERROR: Mod version #{mod_version} already exists!"
	exit 5
end

puts "What is this new mod's description?"
puts "Leave blank to use #{mod_name} #{previous_versions[0]['human_version']}'s description" if previous_versions.count > 0

mod_description = $stdin.gets.chomp
if mod_description.length == 0 and previous_versions.count > 0
	mod_description = previous_versions[0]['description']
end

new_build_number = build_number(mod_identifier)

if previous_versions.count > 0
	previous_build_number = build_number(previous_versions[0]['identifier'])
	if new_build_number <= previous_build_number
		puts "ERROR: New build number #{new_build_number} is less than previous build number #{previous_build_number}"
		exit 6
	end
end

#temporary
unless mod_entries.key? 'Plug-ins'
	mod_entries['Plug-ins'] = []
end

puts "Enter a list of plug-ins you'd like to have for this mod. Leave blank to end the list, or if the mod has no plug-ins"
plugin_names = []
while true
	plugin_name = $stdin.gets.chomp
	if plugin_name.strip.empty?
		break
	end
	plugin_names << plugin_name
end

for plugin_name in plugin_names
	if mod_entries['Plug-ins'].select {|entry| entry['name'] == plugin_name and entry['MDMapPlugin']}.count == 0
		puts "ERROR: Failed to find suitable plug-in #{plugin_name}"
		exit 7
	end
end

puts "Creating new mod...\n\n"
puts "Name: #{mod_name}"
puts "Identifier: #{mod_identifier}"
puts "Version: #{mod_version}"
puts "Description: #{mod_description}"
puts "Plug-ins: " + plugin_names.join(', ') if plugin_names.length > 0
puts "\n"

stock_map_patch_choice = 0
if previous_versions.count > 0
	previous_patches = previous_versions[0]['patches']
	previous_patches = [] unless previous_patches #very old mods may not have a patches field
	stock_patches = previous_patches.select {|patch| stock_maps.include? patch['base_identifier']}
	if stock_patches.count > 0
		stock_map_patch_choice = stock_maps.index(stock_patches[0]['base_identifier']) + 1
	end
end

if stock_map_patch_choice == 0
	puts "What stock map would you like to create a patch from?"

	(['None'] + stock_maps).each_with_index do |stock_map, index|
		puts "[#{index}] #{stock_map}"
	end

	stock_map_patch_choice = $stdin.gets.chomp.to_i
	if stock_map_patch_choice == 0
		puts "Not creating patch from any stock map"
	else
		puts "Selected stock map #{stock_maps[stock_map_patch_choice-1]}"
	end
end

patch_identifiers = (previous_versions.map {|entry| entry['identifier']})[0, max_number_of_patches]
unless stock_map_patch_choice == 0
	stock_map_patch = stock_maps[stock_map_patch_choice-1]
	puts "Selected stock map #{stock_map_patch} for patching...\n\n"
	patch_identifiers << stock_map_patch
end

new_patch_entries = []

if patch_identifiers.count == 0
	puts "Not creating any patches; not necessary."
else
	puts "Creating patches...\n"
	for patch_identifier in patch_identifiers
		old_map_path = nil
		if stock_maps.include? patch_identifier
			old_map_path = stock_map_paths[stock_maps.index(patch_identifier)]
		else
			puts "Downloading #{patch_identifier}..."
			zip_path = "#{OUTPUT_PATH}/#{patch_identifier}.zip"
			print_and_execute_command("curl \"https://halomd.macgamingmods.com/mods/#{patch_identifier}.zip\" -o \"#{zip_path}\"")
			print_and_execute_command("unzip \"#{zip_path}\" -d #{OUTPUT_PATH}")
			FileUtils.rm(zip_path) if File.exists? zip_path
			if File.exists? "#{OUTPUT_PATH}/__MACOSX"
				FileUtils.rm_rf "#{OUTPUT_PATH}/__MACOSX"
			end

			old_map_path = "#{OUTPUT_PATH}/#{patch_identifier}.map"
		end

		patch_name = "#{mod_identifier}_from_#{patch_identifier}.mdpatch"

		new_patch_entries << {'base_identifier' => patch_identifier, 'base_hash' => Digest::MD5.hexdigest(IO.read(old_map_path)), 'path' => "patches/#{patch_name}"}

		puts "\nCreating patch for #{patch_identifier}..."
		print_and_execute_command("bsdiff \"#{old_map_path}\" \"#{mod_path}\" \"#{OUTPUT_PATH}/#{patch_name}\"")

		unless stock_maps.include? patch_identifier
			FileUtils.rm(old_map_path) if File.exists? old_map_path
		end

		puts "\n"
	end
end

puts "Zipping mod..."
print_and_execute_command("zip -jr \"#{OUTPUT_PATH}/#{mod_identifier}.zip\" \"#{mod_path}\"")

puts "\n"

new_mod_entry = {'identifier' => mod_identifier, 'patches' => new_patch_entries, 'description' => mod_description, 'human_version' => mod_version, 'name' => mod_name, 'hash' => Digest::MD5.hexdigest(IO.read(mod_path)), 'plug-ins' => plugin_names}

new_mod_entries = [new_mod_entry] + mod_entries['Mods']

puts "Removing old json file... (#{JSON_PATH})"
FileUtils.rm(JSON_PATH) if File.exists? JSON_PATH

puts "Writing new json file... (#{JSON_PATH})"
File.open(JSON_PATH, "w") do |json_file|
	json_file.write(JSON.pretty_generate({"Mods" => new_mod_entries, "Plug-ins" => mod_entries['Plug-ins']})) #pretty print
end

puts "Writing gzipped json file... (#{JSON_PATH}.gz)"
print_and_execute_command("gzip < \"#{JSON_PATH}\" > \"#{JSON_PATH}.gz\"")

puts "Converting json to plist..."
print_and_execute_command("plutil -convert xml1 \"#{JSON_PATH}\" -o \"#{OUTPUT_PATH}/mods.plist\"")
print_and_execute_command("plutil -convert binary1 \"#{OUTPUT_PATH}/mods.plist\"")

puts "Writing gzipped plist file... (#{OUTPUT_PATH}/mods.plist.gz)"
print_and_execute_command("gzip < \"#{OUTPUT_PATH}/mods.plist\" > \"#{OUTPUT_PATH}/mods.plist.gz\"")
