// Validates a PreToolUse hook payload on stdin.
//
//   node assert-pretooluse.cjs <substring> [more...]
const fs = require("fs");

function fail(message) {
  console.error(message);
  process.exit(1);
}

let payload;
try {
  payload = JSON.parse(fs.readFileSync(0, "utf8"));
} catch (error) {
  fail(`invalid JSON: ${error.message}`);
}

const hookOutput = payload.hookSpecificOutput;
if (!hookOutput || hookOutput.hookEventName !== "PreToolUse") {
  fail("payload is not a PreToolUse hook result");
}

if (hookOutput.permissionDecision && hookOutput.permissionDecision !== "allow") {
  fail(`guard must not block the call, got: ${hookOutput.permissionDecision}`);
}

const context = hookOutput.additionalContext;
if (typeof context !== "string" || context.trim() === "") {
  fail("guard produced no additionalContext");
}

for (const needle of process.argv.slice(2)) {
  if (!context.includes(needle)) {
    fail(`context did not contain: ${needle}`);
  }
}
