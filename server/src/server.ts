import { buildApp } from './app.js';
import { loadConfig } from './config.js';

const config = loadConfig();
const app = await buildApp(config);

async function closeGracefully(signal: NodeJS.Signals): Promise<void> {
  app.log.info({ signal }, 'Shutting down server.');

  try {
    await app.close();
    process.exit(0);
  } catch (error) {
    app.log.error(error);
    process.exit(1);
  }
}

process.once('SIGINT', (signal) => {
  void closeGracefully(signal);
});

process.once('SIGTERM', (signal) => {
  void closeGracefully(signal);
});

try {
  await app.listen({ host: config.host, port: config.port });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}
