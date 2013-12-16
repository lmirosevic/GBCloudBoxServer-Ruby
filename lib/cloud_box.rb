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

RESOURCES_MANIFEST = {
  'MyResource.js' => {:v => 4, :path => 'res/MyResource.js'},
  'ExternalResource.js' => {:v => 3, :url => "https://s3.amazonaws.com/files.somecompany.com/some/path/ExternalResource.js"},
}

RESOURCES_META_PATH = "GBCloudBoxResourcesMeta"
RESOURCES_DATA_PATH = "GBCloudBoxResourcesData2"

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

    #New relic
    require 'newrelic_rpm'
  end

  ############################################### HELPERS ###############################################

  def public_url_for_resource(resource)
    protocol = USE_SSL ? "https" : "http"
    "#{protocol}://#{request.host_with_port}/#{RESOURCES_DATA_PATH}/#{resource}"
  end

  def local_path_for_local_resource(resource)
    if RESOURCES_MANIFEST.has_key?(resource)
      RESOURCES_MANIFEST[resource][:path]

    else
      nil

    end
  end

  def version_for_local_resource(resource)
    if RESOURCES_MANIFEST[resource].has_key?(resource)
      RESOURCES_MANIFEST[resource][:v]

    else
      nil

    end
  end

  ############################################### GBCLOUDBOX META ###############################################

  aget "/#{RESOURCES_META_PATH}/:resource" do
    resource = params[:resource]

    if RESOURCES_MANIFEST.include?(resource)
      #get the resource info
      resource_info = RESOURCES_MANIFEST[resource]
      version = resource_info[:v]
      if resource_info.has_key?(:url)
        url = resource_info[:url]

      elsif resource_info.has_key?(:path)
        url = public_url_for_resource(resource)

      else
        ahalt 404
      end

      #construct the meta obj
      meta_obj = {
        :v => version,
        :url => url
      }

      #return the meta JSON
      headers 'Content-Type' => "application/json"
      body(JSON.generate(meta_obj))
    else
      ahalt 404
    end
  end

  ############################################### LOCAL RESOURCES SERVER ###############################################

  aget "/#{RESOURCES_DATA_PATH}/:resource" do
    resource = params[:resource]

    #get path & version
    path = local_path_for_local_resource(resource)
    version = version_for_local_resource(resource)

    #make sure file exists
        if File.file?(path) and File.readable?(path)
      #get some info about file
      length = File.size(path)
          filename = resource
          type = "application/octet-stream"
          last_modified = File.mtime(path).httpdate
          disposition = "attachment; filename=\"#{filename}\""
          transfer_encoding = "binary"

      #set headers
      headers(
        'Resource-Version'        => version.to_s,
        'Content-Length'        => length.to_s,
        'Content-Type'          => type.strip,
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding'   => transfer_encoding
      )

      #send file
      body File.read(path)
    else
      ahalt 404
    end
  end

  ############################################### PLUMBING ###############################################  

  aget '/alive' do
      body '777'
  end

end
