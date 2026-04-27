#!/bin/bash
set -e

mkdir -p /data/.openclaw

node -e 'let fs=require("fs"); let f="/data/.openclaw/openclaw.json"; let c={}; try{c=JSON.parse(fs.readFileSync(f,"utf8"))}catch(e){}; c.agents=c.agents||{}; c.agents.defaults=c.agents.defaults||{}; c.agents.defaults.model=c.agents.defaults.model||{}; c.agents.defaults.model.primary="openai/gpt-5.5"; fs.writeFileSync(f,JSON.stringify(c,null,2));'

# Install bun if missing (home dir is ephemeral, has to reinstall on every restart)
if [ ! -x "/home/node/.bun/bin/bun" ]; then
  curl -fsSL https://bun.sh/install | bash
fi
export PATH="/home/node/.bun/bin:$PATH"

# Remove dangling symlink that points to wiped home dir
[ -L /data/.bun ] && [ ! -e /data/.bun ] && rm /data/.bun

# Auto-clone gbrain into /data so it persists across deploys
if [ ! -d /data/gbrain ]; then
  git clone https://github.com/garrytan/gbrain.git /data/gbrain
  cd /data/gbrain
  bun install
  bun link
fi

# Auto-clone brain repo into /data so it persists  
if [ ! -d /data/brain ] && [ -n "$GITHUB_PAT" ]; then
  git clone https://$GITHUB_PAT@github.com/coolmorejohn/jarvis-brain.git /data/brain
fi

mkdir -p /data/.gbrain

node -e 'const u="xata"; const p=process.env.XATA_PASSWORD; const h="a5ved9glet6vp1n71ett45d9u8.us-east-1.xata.tech"; const at=String.fromCharCode(64); const url="postgres://"+u+":"+p+at+h+":5432/gbrain_jarvis?sslmode=require"; require("fs").writeFileSync("/data/.gbrain/config.json", JSON.stringify({engine:"postgres",database_url:url})+"\n");'

# Create gbrain wrapper (persistent on /data)
if [ ! -f /data/gbrain-wrapper ]; then
  cat > /data/gbrain-wrapper << 'WRAPEOF'
#!/bin/bash
export PATH="/home/node/.bun/bin:$PATH"
exec bun run /data/gbrain/src/cli.ts "$@"
WRAPEOF
  chmod +x /data/gbrain-wrapper
fi

# Symlink home dir paths to persistent /data (re-create on every boot since home is ephemeral)
mkdir -p /home/node/.local/bin
ln -sfn /data/gbrain /home/node/gbrain
ln -sfn /data/brain /home/node/brain
ln -sfn /data/.gbrain /home/node/.gbrain
ln -sfn /data/gbrain-wrapper /home/node/.local/bin/gbrain
ln -sfn /data/gbrain-wrapper /usr/local/bin/gbrain 2>/dev/null || true

exec openclaw gateway --bind lan --port 10000 --allow-unconfigured
