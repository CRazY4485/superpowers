// Validates a UserPromptSubmit hook payload on stdin.
//
//   node assert-prompt-context.cjs <substring> [more...]
//   node assert-prompt-context.cjs --absent <substring> [more...]
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
if (!hookOutput || hookOutput.hookEventName !== "UserPromptSubmit") {
  fail("payload is not a UserPromptSubmit hook result");
}

const context = hookOutput.additionalContext;
if (typeof context !== "string" || context.trim() === "") {
  fail("injected context was empty");
}

const args = process.argv.slice(2);
const absent = args[0] === "--absent";
const needles = absent ? args.slice(1) : args;

if (needles.length === 0) {
  fail("usage: assert-prompt-context.cjs [--absent] <substring>...");
}

for (const needle of needles) {
  if (absent && context.includes(needle)) {
    fail(`context unexpectedly contained: ${needle}`);
  }
  if (!absent && !context.includes(needle)) {
    fail(`context did not contain: ${needle}`);
  }
}
