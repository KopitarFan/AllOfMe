import { runAdminCli } from './admin.js';

const exitCode = await runAdminCli(process.argv.slice(2));
if (exitCode !== 0) {
  process.exitCode = exitCode;
}
