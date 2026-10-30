#!/bin/sh
set -eu

node - "$1" "$2" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const process = require("node:process");

const [from, to] = process.argv.slice(2);
if (!from || !to) throw new Error("Both build-time and runtime URLs are required");
if (from === to) process.exit(0);

function replaceInDirectory(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      replaceInDirectory(file);
      continue;
    }
    if (!entry.isFile()) continue;
    const contents = fs.readFileSync(file);
    if (!contents.includes(from)) continue;
    // URLs must be literal: dots, query strings and ampersands have special meaning in sed.
    fs.writeFileSync(file, contents.toString("utf8").split(from).join(to));
  }
}

replaceInDirectory("apps/web/.next");
replaceInDirectory("apps/web/public");
NODE
