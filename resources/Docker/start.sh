#!/bin/bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
HTML_FILE="/var/www/html/index.html"

log() {
  echo "[$(date -Iseconds)] $*"
}

log "🚀 Starting EC2 IAM access validation"
log "AWS region: $REGION"

# --- Step 1: Fetch EC2 instances ---
log "🔍 Fetching EC2 instances..."
EC2_JSON=$(aws ec2 describe-instances --region "$REGION" 2>&1)
if [ $? -ne 0 ]; then
  log "❌ Failed to fetch EC2 data"
  echo "$EC2_JSON"
  echo "<html><body><h2>❌ Failed to call EC2 API</h2><pre>$EC2_JSON</pre></body></html>" > "$HTML_FILE"
else
  COUNT=$(echo "$EC2_JSON" | jq '[.Reservations[].Instances[]] | length')
  log "✅ Successfully fetched EC2 data — Found $COUNT instance(s)."

  # Log every EC2 record
  echo "$EC2_JSON" | jq -r '.Reservations[].Instances[] | [.InstanceId, .State.Name, (.PrivateIpAddress // "N/A"), (.PublicIpAddress // "N/A")] | @tsv' |
  while IFS=$'\t' read -r id state pip pub; do
    log "📦 EC2 -> ID: $id | State: $state | Private: $pip | Public: $pub"
  done

  # --- Step 2: Generate HTML ---
  log "📝 Generating Nginx HTML file..."
  {
    echo "<!doctype html>"
    echo "<html><head><meta charset='utf-8'><title>EC2 IAM Access Test</title>"
    echo "<style>body{font-family:Arial;margin:20px;}table{border-collapse:collapse;}td,th{border:1px solid #ccc;padding:6px 12px;}th{background:#f5f5f5;}</style>"
    echo "</head><body>"
    echo "<h1>EC2 IAM Access Verification</h1>"
    echo "<p>Region: <b>$REGION</b></p>"
    echo "<p>Found <b>$COUNT</b> instance(s).</p>"
    echo "<table><tr><th>Instance ID</th><th>State</th><th>Private IP</th><th>Public IP</th></tr>"
    echo "$EC2_JSON" | jq -r '.Reservations[].Instances[] | [.InstanceId, .State.Name, (.PrivateIpAddress // "N/A"), (.PublicIpAddress // "N/A")] | @tsv' |
    while IFS=$'\t' read -r id state pip pub; do
      echo "<tr><td>$id</td><td>$state</td><td>$pip</td><td>$pub</td></tr>"
    done
    echo "</table>"
    echo "<p>Generated at $(date -Iseconds)</p>"
    echo "</body></html>"
  } > "$HTML_FILE"

  log "✅ HTML file created at $HTML_FILE"
fi

# --- Step 3: Nginx operations ---
log "🔧 Checking Nginx status..."
if nginx -t; then
  log "✅ Nginx configuration test passed."
else
  log "❌ Nginx configuration test failed."
fi

log "📂 Showing generated HTML content:"
echo "------------------------------------------------------------"
cat "$HTML_FILE"
echo "------------------------------------------------------------"

log "🔁 Restarting Nginx..."
nginx -s quit || true
sleep 2
nginx
log "✅ Nginx restarted successfully."

log "🌐 Nginx web server running — accessible on port 80"
log "⏱ Container will stay alive for 5 minutes for inspection."

sleep 300

log "🛑 5 minutes elapsed. Stopping Nginx and exiting."
nginx -s quit || true
log "✅ Container shutdown complete."
