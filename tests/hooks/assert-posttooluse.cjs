// Validates a PostToolUse hook payload on stdin and checks substrings.
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

const args = process.argv.slice(2);
let expectedEvent = "PostToolUse";
if (args[0] === "--event") {
  expectedEvent = args[1];
  args.splice(0, 2);
}

const hookOutput = payload.hookSpecificOutput;
if (!hookOutput || hookOutput.hookEventName !== expectedEvent) {
  fail(`expected hookEventName ${expectedEvent}, got ${hookOutput && hookOutput.hookEventName}`);
}

const context = hookOutput.additionalContext;
if (typeof context !== "string" || context.trim() === "") {
  fail("hook produced no additionalContext");
}

for (const needle of args) {
  if (!context.includes(needle)) {
    fail(`context did not contain: ${needle}`);
  }
}
