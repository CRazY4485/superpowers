// Validates a SessionStart hook payload on stdin.
//
//   node assert-session-context.js <substring>            -> must be present
//   node assert-session-context.js --absent <substring>   -> must be absent
//
// Either way the superpowers bootstrap must survive.
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
if (!hookOutput || hookOutput.hookEventName !== "SessionStart") {
  fail("payload is not a SessionStart hook result");
}

const context = hookOutput.additionalContext;
if (typeof context !== "string" || context.trim() === "") {
  fail("injected context was empty");
}

if (!context.includes("You have superpowers")) {
  fail("session context lost the superpowers bootstrap");
}

const args = process.argv.slice(2);
const absent = args[0] === "--absent";
const needle = absent ? args[1] : args[0];

if (!needle) {
  fail("usage: assert-session-context.js [--absent] <substring>");
}

if (absent && context.includes(needle)) {
  fail(`context unexpectedly contained: ${needle}`);
}

if (!absent && !context.includes(needle)) {
  fail(`context did not contain: ${needle}`);
}
