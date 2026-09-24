/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * Starts Metro for the macOS app.
 *
 * The community CLI's `start`/`bundle` commands are registered through a plugin
 * that resolves against a published react-native, which this fork is not. Metro
 * is driven directly instead -- fewer moving parts, and the dev server it
 * serves is the same one RCTBundleURLProvider asks for.
 *
 * @format
 */

const path = require('path');
const Metro = require('metro');

// Port 8081 is often already taken by another dev server on a developer's
// machine. The app resolves `localhost` to ::1 first, so a foreign server bound to
// *:8081 would silently serve its own bundle to this app. Default to 8082 instead;
// METRO_PORT overrides.
const METRO_PORT = Number(process.env.METRO_PORT || 8082);

async function main() {
  const config = await Metro.loadConfig(
    {
      cwd: __dirname,
      config: path.join(__dirname, 'metro.config.js'),
      port: METRO_PORT,
    },
    // Metro also binds `config.server.port` for its websocket endpoints,
    // which defaults to 8081 independently of the HTTP port below. Both have to
    // move or startup fails with EADDRINUSE.
    {server: {port: METRO_PORT}},
  );
  // runServer resolves once the server is listening. Older versions returned
  // the http server directly and newer ones wrap it, so do not assume a shape.
  await Metro.runServer(config, {
    host: '127.0.0.1',
    port: METRO_PORT,
    // RCTBundleURLProvider only trusts `jsLocation` if the packager
    // answers `packager-status:running` on /status; otherwise it silently falls
    // back to guessing localhost:8081. Metro core does not serve /status -- the
    // community CLI middleware normally does -- so serve it here.
    unstable_extraMiddleware: [
      (req, res, next) => {
        if (req.url === '/status' || req.url.startsWith('/status?')) {
          res.setHeader('Content-Type', 'text/plain');
          res.end('packager-status:running');
          return;
        }
        next();
      },
    ],
  });
  console.log(`[metro] listening on http://127.0.0.1:${METRO_PORT}`);
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
