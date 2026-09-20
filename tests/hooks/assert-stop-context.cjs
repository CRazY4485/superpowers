// Validates a Stop hook payload on stdin and checks substrings.
//
//   node assert-stop-context.cjs <substring> [more...]
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
if (!hookOutput || hookOutput.hookEventName !== "Stop") {
  fail("payload is not a Stop hook result");
}

const context = hookOutput.additionalContext;
if (typeof context !== "string" || context.trim() === "") {
  fail("Stop hook produced no additionalContext");
}

for (const needle of process.argv.slice(2)) {
  if (!context.includes(needle)) {
    fail(`context did not contain: ${needle}`);
  }
}
