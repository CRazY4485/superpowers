// Validates a Stop hook nudge payload on stdin.
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
if (!hookOutput || typeof hookOutput !== "object") {
  fail("missing hookSpecificOutput");
}

if (hookOutput.hookEventName !== "Stop") {
  fail(`unexpected hookEventName: ${hookOutput.hookEventName}`);
}

const context = hookOutput.additionalContext;
if (typeof context !== "string" || context.trim() === "") {
  fail("nudge context was empty");
}

if (!context.includes("state.md")) {
  fail("nudge does not name the file to update");
}

if (!context.includes("superpowers:maintaining-project-context")) {
  fail("nudge does not point at the maintaining skill");
}
