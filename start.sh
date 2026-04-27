#!/bin/bash
set -e
mkdir -p /data/.openclaw
node -e '
let fs=require("fs");
let f="/data/.openclaw/openclaw.json";
let c={};
try{c=JSON.parse(fs.readFileSync(f,"utf8"))}catch(e){};
c.plugins=c.plugins||{};
c.plugins.allow=["anthropic","openai","memory-core","telegram"];
c.agents=c.agents||{};
c.agents.defaults=c.agents.defaults||{};
c.agents.defaults.model=c.agents.defaults.model||{};
c.agents.defaults.model.primary="anthropic/claude-opus-4-7";
fs.writeFileSync(f,JSON.stringify(c,null,2));
'
exec openclaw gateway --bind lan --port 10000 --allow-unconfigured
