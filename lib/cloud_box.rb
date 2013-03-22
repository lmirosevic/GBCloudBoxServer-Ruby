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

class CloudBox < Sinatra::Base
	register Sinatra::Async

	############################################### RESOURCES MANIFEST ###############################################

	Resources_meta_path = "GBCloudBoxResourcesMeta"
	Resources_data_path = "GBCloudBoxResourcesData"

	Resources_manifest_local = [
		:"Facebook.js",
	]
	Resources_manifest_external = {
		# :"Facebook.js" => {:v => "3", :url => "https://www.goonbee.com/#{Resources_path}/Facebook.js"},
	}

	############################################### CONFIG ###############################################

	configure :development do
		Use_SSL = false
		set :bind, '0.0.0.0'
		$stdout.sync = true
	end

	configure :production do
		Use_SSL = true

		# Force SSL
		# require 'rack-ssl-enforcer'
		# use Rack::SslEnforcer

		#New relic
		require 'newrelic_rpm'
	end

	############################################### HELPERS ###############################################

	def latest_version_for_local_resource(resource)
		#scour res/#{resource} folder, and fetch the last one 
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
		protocol = Use_SSL ? "https" : "http"
		"#{protocol}://#{request.host_with_port}/#{Resources_data_path}/#{resource}"
	end

	def local_path_for_local_resource(resource)
		"res/#{resource}/#{latest_version_for_local_resource(resource)}"
	end

	############################################### META ROUTE ###############################################

	aget "/#{Resources_meta_path}/:resource_identifier" do
		identifier_s = params[:resource_identifier]
		identifier_sym = identifier_s.to_sym

		#if its a local resource, get the public path. if its an external resource the path is already set
		if Resources_manifest_local.include? identifier_sym
			body({
				:v => latest_version_for_local_resource(identifier_s),
				:url => public_path_for_local_resource(identifier_s)
			}.to_json)
		elsif (resource = Resources_manifest_external[identifier_sym])
			body(resource.to_json)
		else
			ahalt 404
		end
	end

	############################################### LOCAL RESOURCE ROUTE ###############################################

	aget "/#{Resources_data_path}/:resource_identifier" do
		identifier_s = params[:resource_identifier]

		#get path
		path = local_path_for_local_resource(identifier_s)

		#make sure file exists
        if File.file?(path) and File.readable?(path)
			# if File.exist?(path) and File.readable?(path)

			#get some info about file
			version = latest_version_for_local_resource(identifier_s)
			length = File.size(path)
	        filename = identifier_s
	        # type = Rack::Mime::MIME_TYPES[File.extname(path)[1..-1]] || 'text/plain'
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