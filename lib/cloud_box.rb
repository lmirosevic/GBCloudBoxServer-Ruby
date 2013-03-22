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
require 'sinatra/async'
require 'json'

require 'rainbows'
require 'eventmachine'


############################################### RESOURCES MANIFEST ###############################################

	RESOURCES_META_PATH = "GBCloudBoxResourcesMeta"
	RESOURCES_DATA_PATH = "GBCloudBoxResourcesData"

	RESOURCES_MANIFEST_LOCAL = [
		:"Facebook.js",
	]
	RESOURCES_MANIFEST_EXTERNAL = {
		# :"Facebook.js" => {:v => "3", :url => "https://www.goonbee.com/some/path/Facebook.js"},
	}

class CloudBox < Sinatra::Base
	register Sinatra::Async

	############################################### CONFIG ###############################################

	configure :development do
		USE_SSL = false
		set :bind, '0.0.0.0'
		$stdout.sync = true
	end

	configure :production do
		USE_SSL = true

		# Force SSL
		# require 'rack-ssl-enforcer'
		# use Rack::SslEnforcer

		#New relic
		require 'newrelic_rpm'
	end

	############################################### HELPERS ###############################################

	def latest_version_for_local_resource(resource)
		acc = 0
		local_path = "res/#{resource}"

		if File.directory?(local_path) and File.readable?(local_path)
			Dir.foreach(local_path) do |version|
				next if version == '.' or version == '..'
				if version.to_i > acc
					acc = version.to_i
				end
			end

			acc
		else
			nil
		end

	end

	def public_path_for_local_resource(resource)
		protocol = USE_SSL ? "https" : "http"
		"#{protocol}://#{request.host_with_port}/#{RESOURCES_DATA_PATH}/#{resource}"
	end

	def local_path_for_local_resource(resource)
		"res/#{resource}/#{latest_version_for_local_resource(resource)}"
	end

	############################################### META ROUTE ###############################################

	aget "/#{RESOURCES_META_PATH}/:resource_identifier" do
		identifier_s = params[:resource_identifier]
		identifier_sym = identifier_s.to_sym

		#if its a local resource, get the public path. if its an external resource the path is already set
		if RESOURCES_MANIFEST_LOCAL.include? identifier_sym
			headers 'Content-Type' => "application/json"
			body({
				:v => latest_version_for_local_resource(identifier_s),
				:url => public_path_for_local_resource(identifier_s)
			}.to_json)
		elsif (resource = RESOURCES_MANIFEST_EXTERNAL[identifier_sym])
			body(resource.to_json)
		else
			ahalt 404
		end
	end

	############################################### LOCAL RESOURCE ROUTE ###############################################

	aget "/#{RESOURCES_DATA_PATH}/:resource_identifier" do
		identifier_s = params[:resource_identifier]

		#get path
		path = local_path_for_local_resource(identifier_s)

		#make sure file exists
        if File.file?(path) and File.readable?(path)
			#get some info about file
			version = latest_version_for_local_resource(identifier_s)
			length = File.size(path)
	        filename = identifier_s
	        type = "application/octet-stream"
	        last_modified = File.mtime(path).httpdate
	        disposition = "attachment; filename=\"#{filename}\""
	        transfer_encoding = "binary"

			#set headers
			headers(
				'Resource-Version' 				=> version.to_s,
				'Content-Length' 				=> length.to_s,
				'Content-Type' 					=> type.strip,
				'Content-Disposition' 			=> disposition,
				'Content-Transfer-Encoding' 	=> transfer_encoding
			)

			#send file
			body File.read(path)
		else
			ahalt 404
		end
	end

end