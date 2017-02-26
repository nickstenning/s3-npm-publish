s3-npm-publish
==============

This is a tool to publish an [NPM][1] package to an [Amazon S3][2] bucket using
sensible defaults. It assumes that:

- you are releasing prebuilt assets in your NPM package
- you wish to expose the entirety of your package in the S3 bucket for each
  released version

It will be most useful only if you also:

- define a `main` entrypoint in your package's `package.json`
- ensure your entrypoint file is capable of loading the remainder of your
  packages assets as necessary from the bucket HTTP URL (or CDN URL)

To be explicit, this means that you will probably need your entrypoint script
to:

1. Know what version of your package it is from.
2. Know the URL at which your bucket can be accessed over HTTP.
3. Manage the loading of the rest of your application using 1, 2, and the URL
   conventions described below.

[1]: https://www.npmjs.com/
[2]: https://aws.amazon.com/documentation/s3/

Usage
-----

    docker run --rm \
      -e AWS_ACCESS_KEY_ID=... \
      -e AWS_SECRET_ACCESS_KEY=... \
      nickstenning/s3-npm-publish <pkgname> <s3path>

For example, if you were releasing the `mypkg` package:

    docker run --rm \
      -e AWS_ACCESS_KEY_ID=... \
      -e AWS_SECRET_ACCESS_KEY=... \
      nickstenning/s3-npm-publish mypkg s3://cdn.mypkg.org

See the "Example scenario" below to understand how `s3-npm-publish` lays out
files in your bucket.

To release a specific version of a package (any NPM version identifier will
work):

    docker run --rm \
      -e AWS_ACCESS_KEY_ID=... \
      -e AWS_SECRET_ACCESS_KEY=... \
      nickstenning/s3-npm-publish mypkg@2.0.1 s3://cdn.mypkg.org

To release to a path other than the bucket root:

    docker run --rm \
      -e AWS_ACCESS_KEY_ID=... \
      -e AWS_SECRET_ACCESS_KEY=... \
      nickstenning/s3-npm-publish mypkg s3://cdn.mypkg.org/static

If you are running in an environment where the AWS CLI tools will be able to
obtain credentials without you explicitly providing them (for example on an EC2
instance with an appropriate instance role profile) you can omit the `AWS_*`
environment variables:

    docker run --rm nickstenning/s3-npm-publish mypkg s3://cdn.mypkg.org

Example scenario
----------------

You have a package, `giraffejs`, which contains a JavaScript application which
you intend to release to an S3 bucket, `s3://assets.giraffejs.com`. The package
contains the following assets:

    index.js
    dist/app.js
    dist/app.css

First you would release the `giraffejs` package to NPM as usual, and then you
would run `s3-npm-publish` as follows:

    docker run --rm \
      -e AWS_ACCESS_KEY_ID=... \
      -e AWS_SECRET_ACCESS_KEY=... \
      nickstenning/s3-npm-publish giraffejs s3://assets.giraffejs.com

This automatically detects that the latest version of the `giraffejs` package is
(for example) `1.2.3` and will upload the contents of the package to:

    s3://assets.giraffejs.com/giraffejs/1.2.3/index.js
    s3://assets.giraffejs.com/giraffejs/1.2.3/dist/app.js
    s3://assets.giraffejs.com/giraffejs/1.2.3/dist/app.css

Each of these files will be served with [HTTP `Cache-Control` headers][3] which
ensure that they essentially never expire from any cache:

    Cache-Control: public, max-age=315360000, immutable

[3]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control

If `package.json` contains a `main` key, the file to which it points will be
used to set up aliases in the bucket. For example if `package.json` contains

    {
      ...
      "main": "./index.js",
      ...
    }

then `s3-npm-publish` will upload `index.js` to

    s3://assets.giraffejs.com/giraffejs@1.2.3
    s3://assets.giraffejs.com/giraffejs@1.2
    s3://assets.giraffejs.com/giraffejs@1
    s3://assets.giraffejs.com/giraffejs

The first of these (with the full version number) will be served with similar
`Cache-Control` headers to the rest of the package. The latter three (which may
be updated when a new version is released) are served with a much shorter TTL
and a request to user agents to revalidate the resource if the cache entry goes
stale:

    Cache-Control: public, max-age=1800, must-revalidate

This allow you to easily publish new versions of your package, and clients
pointing to (for example) the `1.2` alias will receive the new entrypoint script
when a new version of the package in the `1.2.X` series is released.

Unsolicited advice
------------------

If you are serving a JavaScript application from an S3 bucket, you should
probably set up a CloudFront distribution or other CDN to front your bucket.
This will improve the perceived loading speed of your package assets, and (if
you have substantial traffic) likely reduce your costs.

License
-------

This project is released under the MIT license, a copy of which is provided in
`LICENSE`.
