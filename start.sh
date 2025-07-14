#!/usr/bin/env bash

# vkQuake Server Startup Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting vkQuake Server...${NC}"

# Check if game files exist
if [ ! -f "/quake/game/id1/pak0.pak" ]; then
    echo -e "${RED}ERROR: pak0.pak not found in /quake/game/id1/${NC}"
    echo -e "${YELLOW}Please mount your Quake game files to /quake/game${NC}"
    exit 1
fi

# Create config directory if it doesn't exist
mkdir -p /quake/config
mkdir -p /quake/logs

# Function to create server config
create_server_config() {
    local config_file="/quake/config/server.cfg"
    
    cat > "$config_file" << EOF
// vkQuake Server Configuration
// Generated automatically - do not edit manually

// Server settings
hostname "${QUAKE_SERVER_NAME}"
maxplayers ${QUAKE_MAX_PLAYERS}
port ${QUAKE_PORT}

// Game mode settings
deathmatch ${QUAKE_DEATHMATCH}
coop ${QUAKE_COOP}
teamplay ${QUAKE_TEAMPLAY}
skill ${QUAKE_SKILL}

// Match settings
fraglimit ${QUAKE_FRAGLIMIT}
timelimit ${QUAKE_TIMELIMIT}

// Server behavior
pausable 0
sv_aim 1
sv_maxspeed 320
sv_friction 4
sv_edgefriction 2
sv_gravity 800

// Admin settings
EOF

    if [ -n "$QUAKE_ADMIN_PASSWORD" ]; then
        echo "rcon_password \"${QUAKE_ADMIN_PASSWORD}\"" >> "$config_file"
    fi
    
    echo -e "${GREEN}Server config created at $config_file${NC}"
}

# Function to setup bot support
setup_bots() {
    if [ "$QUAKE_ENABLE_BOTS" = "1" ]; then
        if [ -d "/quake/mods/frogbot" ]; then
            echo -e "${GREEN}Setting up Frogbot support...${NC}"
            # Copy frogbot files to appropriate game directory
            local game_dir="/quake/game"
            if [ -n "$QUAKE_MOD" ]; then
                game_dir="/quake/game/$QUAKE_MOD"
            else
                game_dir="/quake/game/id1"
            fi
            
            # This would be implementation-specific for the actual bot mod
            echo "Bot count: $QUAKE_BOT_COUNT"
            echo "Bot skill: $QUAKE_BOT_SKILL"
        else
            echo -e "${YELLOW}Warning: Bot support requested but bot mod not found${NC}"
        fi
    fi
}

# Function to setup map rotation
setup_map_rotation() {
    if [ "$QUAKE_ROTATION_MODE" = "1" ]; then
        local rotation_file="/quake/config/maprotation.cfg"
        
        cat > "$rotation_file" << EOF
// Map rotation configuration
// Maps: ${QUAKE_MAP_ROTATION}

alias nextmap_e1m1 "map e1m2"
alias nextmap_e1m2 "map e1m3"
alias nextmap_e1m3 "map e1m4"
alias nextmap_e1m4 "map e1m5"
alias nextmap_e1m5 "map e1m6"
alias nextmap_e1m6 "map e1m7"
alias nextmap_e1m7 "map e1m8"
alias nextmap_e1m8 "map e1m1"
alias nextmap_start "map e1m1"
EOF
        
        echo -e "${GREEN}Map rotation configured${NC}"
    fi
}

# Function to build command line arguments
build_command_args() {
    local args=()
    
    # Basic server settings
    args+=("-dedicated" "$QUAKE_MAX_PLAYERS")
    args+=("-port" "$QUAKE_PORT")
    
    # Game directory
    args+=("-basedir" "/quake/game")
    
    # Config directory
    args+=("-config" "/quake/config")
    
    # Mod support
    if [ -n "$QUAKE_MOD" ]; then
        args+=("-game" "$QUAKE_MOD")
    fi
    
    # Memory settings
    args+=("-mem" "64")
    args+=("-zone" "8192")
    
    # Console debug
    if [ "$QUAKE_CONDEBUG" = "1" ]; then
        args+=("-condebug")
    fi
    
    # Game mode
    args+=("+deathmatch" "$QUAKE_DEATHMATCH")
    args+=("+coop" "$QUAKE_COOP")
    args+=("+teamplay" "$QUAKE_TEAMPLAY")
    args+=("+skill" "$QUAKE_SKILL")
    
    # Match settings
    args+=("+fraglimit" "$QUAKE_FRAGLIMIT")
    args+=("+timelimit" "$QUAKE_TIMELIMIT")
    
    # Server info
    args+=("+hostname" "\"$QUAKE_SERVER_NAME\"")
    args+=("+maxplayers" "$QUAKE_MAX_PLAYERS")
    
    # Admin password
    if [ -n "$QUAKE_ADMIN_PASSWORD" ]; then
        args+=("+rcon_password" "\"$QUAKE_ADMIN_PASSWORD\"")
    fi
    
    # Starting map
    args+=("+map" "$QUAKE_MAP")
    
    # Execute server config
    args+=("+exec" "server.cfg")
    
    echo "${args[@]}"
}

# Function to handle graceful shutdown
cleanup() {
    echo -e "\n${YELLOW}Shutting down vkQuake server...${NC}"
    if [ -n "$SERVER_PID" ]; then
        kill -TERM "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    echo -e "${GREEN}Server shutdown complete${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Main execution
main() {
    echo -e "${GREEN}=== vkQuake Server Configuration ===${NC}"
    echo -e "Server Name: ${YELLOW}$QUAKE_SERVER_NAME${NC}"
    echo -e "Max Players: ${YELLOW}$QUAKE_MAX_PLAYERS${NC}"
    echo -e "Game Mode: ${YELLOW}DM:$QUAKE_DEATHMATCH COOP:$QUAKE_COOP TEAM:$QUAKE_TEAMPLAY${NC}"
    echo -e "Port: ${YELLOW}$QUAKE_PORT${NC}"
    echo -e "Starting Map: ${YELLOW}$QUAKE_MAP${NC}"
    echo -e "Mod: ${YELLOW}${QUAKE_MOD:-id1}${NC}"
    echo -e "Bots: ${YELLOW}${QUAKE_ENABLE_BOTS:-0}${NC}"
    echo -e "=================================="
    
    # Create server configuration
    create_server_config
    
    # Setup bots if enabled
    setup_bots
    
    # Setup map rotation
    setup_map_rotation
    
    # Build command arguments
    local cmd_args
    cmd_args=$(build_command_args)
    
    echo -e "${GREEN}Starting server with command:${NC}"
    echo -e "${YELLOW}/quake/bin/quake $cmd_args${NC}"
    
    # Change to logs directory for output
    cd /quake/logs
    
    # Start the server
    exec /quake/bin/quake $cmd_args &
    SERVER_PID=$!
    
    echo -e "${GREEN}Server started with PID: $SERVER_PID${NC}"
    echo -e "${GREEN}Server logs will be written to /quake/logs/${NC}"
    echo -e "${GREEN}Connect to server at: <server_ip>:$QUAKE_PORT${NC}"
    
    # Wait for the server process
    wait $SERVER_PID
}

# Run main function
main "$@"
