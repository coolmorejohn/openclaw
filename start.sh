#!/bin/bash
set -e

# Plugin allowlist + default model (preserved across all restarts)
mkdir -p /data/.openclaw
node -e '
let fs=require("fs");
let f="/data/.openclaw/openclaw.json";
let c={};
try{c=JSON.parse(fs.readFileSync(f,"utf8"))}catch(e){};
c.plugins=c.plugins||{};
c.plugins.allow=["anthropic","openai","memory-core","active-memory","memory-wiki","telegram","skill-workshop","webhooks","browser"];
c.agents=c.agents||{};
c.agents.defaults=c.agents.defaults||{};
c.agents.defaults.model=c.agents.defaults.model||{};
c.agents.defaults.model.primary="anthropic/claude-opus-4-7";
fs.writeFileSync(f,JSON.stringify(c,null,2));
'

# Auto-clone gbrain into /data so it persists across deploys
if [ ! -d /data/gbrain ]; then
  git clone https://github.com/garrytan/gbrain.git /data/gbrain
  cd /data/gbrain
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
  bun install
  bun link
fi

# Auto-clone brain repo into /data so it persists  
if [ ! -d /data/brain ] && [ -n "$GITHUB_PAT" ]; then
  git clone https://$GITHUB_PAT@github.com/coolmorejohn/jarvis-brain.git /data/brain
fi

# Write gbrain config (uses Xata DB)
mkdir -p /data/.gbrain
node -e '
const u="xata";
const p=process.env.XATA_PASSWORD;
const h="a5ved9glet6vp1n71ett45d9u8.us-east-1.xata.tech";
const url=`postgres://${u}:${p}` + String.fromCharCode(64) + `${h}:5432/gbrain_jarvis?sslmode=require`;
require("fs").writeFileSync("/data/.gbrain/config.json", JSON.stringify({engine:"postgres",database_url:url})+"\n");
'

# Symlink home dir paths to persistent /data
ln -sfn /data/gbrain /home/node/gbrain
ln -sfn /data/brain /home/node/brain
ln -sfn /data/.gbrain /home/node/.gbrain

exec openclaw gateway --bind lan --port 10000 --allow-unconfigured
