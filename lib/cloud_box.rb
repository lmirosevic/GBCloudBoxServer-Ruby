# cloud_box.rb
# GBCloudBox

# Created by Luka Mirosevic on 20/03/2013.
# Copyright (c) 2013 Goonbee. All rights reserved.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'sinatra'
require 'json'

########### Manifest ###########

Resources_meta_path = "GBCloudBoxResourcesMeta"
Resources_data_path = "GBCloudBoxResourcesData"
Resources_manifest_local = [
	:"Facebook.js",
]
Resources_manifest_external = {
	# :"Facebook.js" => {:v => "3", :url => "https://www.goonbee.com/#{Resources_path}/Facebook.js"},
}
Use_SSL = true

########### Helpers ###########

def latest_version_for_local_resource(resource)
	#scour res/#{resource} folder, and fetch the last one 
	acc = 0
	local_path = "res/#{resource}"

	Dir.foreach(local_path) do |version|
		next if version == '.' or version == '..'
		if version.to_i > acc
			acc = version.to_i
		end
	end

	acc
end

def public_path_for_local_resource(resource)
	protocol = Use_SSL ? "https" : "http"
	"#{protocol}://#{request.host_with_port}/#{Resources_data_path}/#{resource}"
end

def local_path_for_local_resource(resource)
	"res/#{resource}/#{latest_version_for_local_resource(resource)}"
end

########### Config ###########

configure :development do
	$stdout.sync = true
	Use_SSL = false
end

########### Meta Route ###########

get "/#{Resources_meta_path}/:resource_identifier" do
	identifier_s = params[:resource_identifier]
	identifier_sym = identifier_s.to_sym

	#if its a local resource, get the public path. if its an external resource the path is already set
	if Resources_manifest_local.include? identifier_sym
		{
			:v => latest_version_for_local_resource(identifier_s),
			:url => public_path_for_local_resource(identifier_s)
		}.to_json
	elsif (resource = Resources_manifest_external[identifier_sym])
		resource.to_json
	else
		halt 404
	end
end

########### Local Resources Route ###########

get "/#{Resources_data_path}/:resource_identifier" do
	identifier_s = params[:resource_identifier]

	#set headers
	response.headers['Resource-Version'] = latest_version_for_local_resource(identifier_s).to_s

	#send file
	send_file(local_path_for_local_resource(identifier_s), :filename => identifier_s)

	# check to see if the folder exists, if so get the latest version, set the Resource-Version http header, return the resource data #foo
end

# logging