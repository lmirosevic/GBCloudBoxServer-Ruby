GBCloudBox Server (Ruby)
============

GBCloudBox is a framework for over-the-air, asynchronous, in-the-background, resource syncing between iOS or Mac OS X apps and a server. Let's say your app depends on a javascript resoruce called `MyResource.js`, but you want to be able to change it often without resubmitting to the app store. GBCloudBox allows you to ship a bundled version of the resource inside your app, and push updated versions of your resource to the cloud and have your apps in the wild sync the resource once you push a new version.

This is a server implementation for the GBCloudBox, and is configured for 1 click deployment to Heroku. It is implemented using Ruby with Async Sinatra (Eventmachine) and is deployed with the Rainbows server. It consumes about 35MB/process. Configured to spawn 12 worker processes on Heroku, corresponding to 3 per core. Has been thoroughly load tested and can sustain a peak performance with 0% error rate of 1000 concurrent requests with an end-to-end response time of ~750ms on a single dyno (i.e. for free!); this corresponds to about 1300 req/s with a concurrency of 4000 simulatenously connected users. The server features graceful degradation at overload capacity: tested at 4000 concurrent users, the server will maintain a ~800ms response rate with 38% dropped requests for a throughput of 3100 successful req/s. This is all on a single free dyno. App is stateless so you can scale your dynos and multiply performance linearly for the price of additional dynos. Or you can create several single-dyno free Heroku apps, and load balance on the client for free.

Dependency management using bundler.  Includes NewRelic monitoring.

Usage
------------

Save your resources in the `./res` folder. Resources should be saved as a folder with numbered files inside to indicate versions. e.g. you would save the file `MyResource.js` version 4 as `./res/MyResource.js/4`. File version should be incrementing integers.

Then add the file to the resource manifest:

```ruby
RESOURCES_MANIFEST_LOCAL = [
	:"MyResource.js",
]
```

Alternatively you can host the resource externally, like on Amazon S3, in which case just point to the latest file url and set a version with it:

```ruby
RESOURCES_MANIFEST_EXTERNAL = {
	:"ExternalResource.js" => {:v => "3", :url => "https://s3.amazonaws.com/files.somecompany.com/some/path/ExternalResource.js"},
}
```

You can configure the server API path using (make sure to set the same thing in client):

```ruby
RESOURCES_META_PATH = "GBCloudBoxResourcesMeta"
RESOURCES_DATA_PATH = "GBCloudBoxResourcesData"
```

Local testing
------------

First update dependencies (make sure you have bundler installed, if not `gem install bundler` first):

```sh
bundle update
```

Then launch using foreman (if you don't have foreman installed: first do `gem install foreman`):

```sh
foreman start
```

iOS & Mac OS X Client (Objective-C)
------------

See: [github.com/lmirosevic/GBCloudBoxClient](https://github.com/lmirosevic/GBCloudBoxClient)


Copyright & License
------------

Copyright 2013 Luka Mirosevic

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.