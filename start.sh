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
c.agents.defaults.model.primary="openai/gpt-5.5";
fs.writeFileSync(f,JSON.stringify(c,null,2));
'

# Auto-clone gbrain into /data so it persists across deploys
if [ ! -d /data/gbrain ]; then
  git clone https://github.com/garrytan/gbrain.git /data/gbrain
  cd /data/gbrain
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
  bun inst
