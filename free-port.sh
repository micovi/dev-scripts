#!/bin/bash

# Color codes for pretty output 🌈
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Help message
usage() {
  echo -e "${BLUE}Usage:${NC} $0 <port> [--force | --list | --get-path]"
  echo -e "  <port>       Port number to check or free"
  echo -e "  --force      Kill the process immediately, no confirmation"
  echo -e "  --list       List all used ports"
  echo -e "  --get-path   Show process and executable path, do not kill"
}

# List all occupied ports
list_ports() {
  echo -e "${YELLOW}🔍 Listing all used ports:${NC}"
  lsof -nP -i -P | grep LISTEN
}

# Check if lsof is installed
if ! command -v lsof &> /dev/null; then
  echo -e "${RED}❌ lsof is not installed. Please install it first.${NC}"
  exit 1
fi

# Check arguments
if [ "$1" == "--list" ]; then
  list_ports
  exit 0
fi

if [ -z "$1" ]; then
  echo -e "${RED}❌ Error:${NC} No port provided."
  usage
  exit 1
fi

PORT=$1
ACTION=$2

PID=$(lsof -ti :$PORT)

if [ -z "$PID" ]; then
  echo -e "${GREEN}✅ Port $PORT is already free.${NC}"
  exit 0
fi

# Show process info
echo -e "${YELLOW}⚠️  Port $PORT is in use by:${NC}"
lsof -nP -i :$PORT

# Show full path to executable (more reliable method)
FULL_PATH=$(lsof -p $PID | grep txt | awk '{print $NF}')

if [ -n "$FULL_PATH" ]; then
  echo -e "${BLUE}🧩 Executable path:${NC} $FULL_PATH"
else
  echo -e "${RED}⚠️  Could not resolve executable path (process might be gone or access denied).${NC}"
fi

# If get-path flag is provided, stop here
if [ "$ACTION" == "--get-path" ]; then
  echo -e "${GREEN}ℹ️  Info mode: no action taken.${NC}"
  exit 0
fi

# If force flag is provided, kill immediately
if [ "$ACTION" == "--force" ]; then
  kill -9 $PID
  echo -e "${GREEN}✅ Process $PID has been killed. Port $PORT is now free!${NC}"
  exit 0
fi

# Safe mode: ask for confirmation
read -p "❓ Do you want to kill this process? (y/N): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
  kill -9 $PID
  echo -e "${GREEN}✅ Process $PID has been killed. Port $PORT is now free!${NC}"
else
  echo -e "${RED}🚫 Action cancelled. Port $PORT is still in use.${NC}"
fi
