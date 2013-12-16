GBCloudBox Server (Ruby)
============

GBCloudBox is a framework for over-the-air, asynchronous, in-the-background, resource syncing between iOS/Mac OS X apps and a server. Let's say your app depends on a javascript resource file called `MyResource.js`, but you want to be able to change it often without resubmitting your entire app to the App Store. GBCloudBox allows you to ship a bundled version of the resource inside your app, publish and distribute your app, and then once the app is out in the wild push updated versions of your resource to the cloud and have your apps in the wild automatically sync the resource as soon as the new one becomes available.

This is a server implementation for the GBCloudBox, and is configured for 1 click deployment to Heroku. It is implemented using Ruby with Async Sinatra (Eventmachine) and is deployed with the Rainbows server. It consumes about 35MB/process. It's currently configured to spawn 12 worker processes on Heroku, corresponding to 3 per core. Has been thoroughly load tested and can sustain a peak performance with 0% error rate of 1000 concurrent requests with an end-to-end response time of ~750ms on a single dyno (i.e. for free!); this corresponds to about 1300 req/s with a concurrency of 1000 simulatenously connected users. The server features graceful degradation at overload capacity: tested at 4000 concurrent users, the server will maintain a ~800ms response rate with 38% dropped requests for a throughput of 3100 successful req/s. This is all on a single free dyno. App is stateless so you can scale your dynos and multiply performance linearly for the price of additional dynos. Or you can create several single-dyno free Heroku apps, and load balance on the client for free (the client library has a feature to sync with multiple servers).

Dependency management using bundler.  Includes NewRelic monitoring.

Usage
------------

List your files in the resources manifest:

```ruby
RESOURCES_MANIFEST = {
	'SomeResource.js' => {:v => 4, :path => 'res/SomeResource.js'},
	'SomeOtherExternalResource.js' => {:v => 3, :url => 'https://s3.amazonaws.com/files.somecompany.com/some/path/SomeOtherExternalResource.js'},
}
```

Notice how resources can point to both an internal path like `res/MyResource.js`, or an external URL like `https://s3.amazonaws.com/files.somecompany.com/some/path/SomeOtherExternalResource.js`.

You can configure the server API paths if you need to (make sure to set the same thing in client):

```ruby
RESOURCES_META_PATH = "GBCloudBoxResourcesMeta"
RESOURCES_DATA_PATH = "GBCloudBoxResourcesData"
```

That's it. Client library will take care of the rest.

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

Implementing your own server
------------

You can always create your own implementation of the server, the protocol is very simple... you need to implement a `meta` GET url which returns a JSON string like this:
```json
{
	"v": "3",
	"url": "http://www.my-company.com/path/to/the/actual/resource.zip"
}
```

The path to this JSON can be set in the client library, it defaults to `/GBCloudBoxResourcesMeta/<resource>`. e.g. if your server is at `files.my-company.com` and the resource is called `MyResource.zip`, it will be `https://files.my-company.com/GBCloudBoxResourcesMeta/MyResource.zip`.

That basically tells the client what the latest version is and where to find it. Then just make sure that the resouce (in this case `resource.zip`) is actually available at the url you claim it's at. The client will check the meta path to see if there's a newer version out, and if there is it will get it from the url your server specifies. You can serve the actual file from something like Amazon S3, a CDN, or your own server.

iOS & Mac OS X Client (Objective-C)
------------

See: [github.com/lmirosevic/GBCloudBoxClient](https://github.com/lmirosevic/GBCloudBoxClient)


Copyright & License
------------

Copyright 2013 Luka Mirosevic

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/lmirosevic/gbcloudboxserver-ruby/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
