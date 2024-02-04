#!/bin/sh

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Check if MetricsType is defined and is either "node" or "app"
if [ -z "$MetricsType" ] || [ "$MetricsType" != "node" ] && [ "$MetricsType" != "app" ]; then
    log "Error: MetricsType must be defined and set to either 'node' or 'app'."
    exit 1
fi

# Check if Target is defined for app metrics
if [ -z "$Target" ]; then
    log "Error: Target is not defined."
    exit 1
fi

# Check MetricsType and act accordingly
if [ "$MetricsType" = "node" ]; then
    log "Fetching metrics from ${Target}/metrics..."
    #curl "${Target}/metrics" > metrics.txt
    ./nodeScraper.sh 
else
    # Check if CustomMetrics is defined for app metrics
    # if [ -z "$CustomMetrics" ]; then
    #     log "Error: CustomMetrics is not defined for app metrics."
    #     exit 1
    # fi

    log "Fetching metrics from ${Target}/metrics..."
    ./appScraper.sh
fi

# cat metrics.txt

log "Metrics extraction complete"

while true; do 
    sleep 100
done