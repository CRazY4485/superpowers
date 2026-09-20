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

const args = process.argv.slice(2);
const expectDeny = args[0] === "--deny";
const needles = expectDeny ? args.slice(1) : args;

if (expectDeny) {
  if (hookOutput.permissionDecision !== "deny") {
    fail(`expected a deny decision, got: ${hookOutput.permissionDecision}`);
  }
} else if (hookOutput.permissionDecision && hookOutput.permissionDecision !== "allow") {
  fail(`hook must not block the call, got: ${hookOutput.permissionDecision}`);
}

const context = expectDeny
  ? hookOutput.permissionDecisionReason
  : hookOutput.additionalContext;

if (typeof context !== "string" || context.trim() === "") {
  fail(expectDeny ? "deny carried no reason" : "hook produced no additionalContext");
}

for (const needle of needles) {
  if (!context.includes(needle)) {
    fail(`text did not contain: ${needle}`);
  }
}
