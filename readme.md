# vkQuake Server Docker

> **⚠️ Disclaimer:**
> This project is **not affiliated with id Software**, Bethesda, or any official Quake project.  
> This repository is **solely for personal use**.  
> They are **not** affiliated with, endorsed by, or connected in any way to the [vkQuake](https://github.com/Novum/vkQuake) project.  
> Use at your own risk. No warranties are provided.

---

## Status

🔧 **Under Construction**  
This project is still being set up.
Stay tuned.

---

A containerized Quake server based on vkQuake/QuakeSpasm with full configuration support via environment variables.

## Features

- **Multi-architecture support**: AMD64 and ARM64 (Raspberry Pi 4 compatible)
- **User-friendly**: Run with custom UID/GID for proper file permissions
- **Flexible configuration**: All server settings via environment variables
- **Map rotation**: Automatic map cycling support
- **Bot support**: Ready for bot mods (Frogbot integration)
- **Mod support**: Easy mod loading (CTF, DOPA, etc.)
- **Health monitoring**: Built-in health checks
- **Separate volumes**: Game files, config, and logs in separate mounts

## Quick Start

1. **Prepare game files**: Place your Quake game files in the structure shown below
2. **Configure environment**: Copy `.env.example` to `.env` and adjust settings
3. **Start server**: Run `docker-compose up -d`

## Directory Structure

Your game directory should look like this:

```
game/
├── ctf/
├── dopa/
├── hipnotic/
│   └── music/
├── id1/
│   ├── pak0.pak
│   ├── pak1.pak
│   └── music/
├── mg1/
├── movies/
└── rogue/
    └── music/
```

## Configuration

All configuration is done via environment variables. Copy `.env.example` to `.env` and customize:

### Server Settings
- `QUAKE_SERVER_NAME`: Server name displayed in browser
- `QUAKE_MAX_PLAYERS`: Maximum player count (1-16)
- `QUAKE_PORT`: Server port (default: 26000)

### Game Mode
- `QUAKE_DEATHMATCH`: Enable deathmatch (1/0)
- `QUAKE_COOP`: Enable cooperative mode (1/0)
- `QUAKE_TEAMPLAY`: Enable team play (1/0)
- `QUAKE_SKILL`: Skill level (0-3)

### Match Settings
- `QUAKE_FRAGLIMIT`: Frag limit for map change
- `QUAKE_TIMELIMIT`: Time limit in minutes

### Map Rotation
- `QUAKE_MAP`: Starting map
- `QUAKE_MAP_ROTATION`: Comma-separated list of maps
- `QUAKE_ROTATION_MODE`: Enable rotation (1/0)

### Admin
- `QUAKE_ADMIN_PASSWORD`: RCON password for admin access

### Bots
- `QUAKE_ENABLE_BOTS`: Enable bot support (1/0)
- `QUAKE_BOT_COUNT`: Number of bots (1-16)
- `QUAKE_BOT_SKILL`: Bot skill level (0-3)

### Mods
- `QUAKE_MOD`: Mod directory name (e.g., "ctf", "dopa")

## Usage

### Starting the Server

```bash
# Copy and edit configuration
cp .env.example .env
nano .env

# Start the server
docker-compose up -d

# View logs
docker-compose logs -f
```

### Connecting to Server

From vkQuake client:
1. Open console with `~`
2. Type: `connect <server_ip>:26000`

Or use the server browser to find "My vkQuake Server" on your LAN.

### Admin Commands

Connect to server and use RCON:
```
rcon_password <your_admin_password>
rcon status
rcon changelevel e1m1
rcon kick <player_name>
```

### Map Management

The server supports automatic map rotation. Maps change when:
- Frag limit is reached
- Time limit is reached
- Admin forces map change

## File Permissions

The container runs as a non-root user. Set `PUID` and `PGID` in your `.env` to match your host user:

```bash
# Get your user ID and group ID
id

# Set in .env file
PUID=1000
PGID=1000
```

## Mod Support

### Adding Mods

1. Place mod files in appropriate game subdirectory
2. Set `QUAKE_MOD=mod_name` in `.env`
3. Restart container

### Bot Support

The container includes Frogbot integration. To enable:
1. Set `QUAKE_ENABLE_BOTS=1`
2. Configure bot count and skill
3. Restart server

## Troubleshooting

### Common Issues

**Server not visible on LAN:**
- Check firewall rules for UDP port 26000
- Verify `QUAKE_PORT` environment variable
- Ensure Docker network allows UDP traffic

**Game files not found:**
- Verify pak0.pak exists in `/quake/game/id1/`
- Check file permissions and ownership
- Ensure volume mounts are correct

**Performance issues:**
- Adjust Docker resource limits
- Consider using SSD storage for game files
- Monitor container resource usage

### Logs

```bash
# View server logs
docker-compose logs vkquake-server

# Follow real-time logs
docker-compose logs -f vkquake-server

# Check container status
docker-compose ps
```

## Building from Source

```bash
# Build locally
docker build -t vkquake-server .

# Build for multiple architectures
docker buildx build --platform linux/amd64,linux/arm64 -t vkquake-server .
```

## License

This project follows the same license as vkQuake and QuakeSpasm (GNU GPL v2).
See: [vkQuake LICENSE](https://github.com/Novum/vkQuake/blob/master/LICENSE.txt)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Support

For issues related to:
- **Container/Docker**: Open an issue in this repository
- **vkQuake engine**: Visit the [vkQuake repository](https://github.com/Novum/vkQuake)
- **Quake gameplay**: Check [QuakeWiki](https://quakewiki.org/) or [QuakeOne forums](https://quakeone.com/)

## Disclaimer & Legal

- No affiliation: This repo is independent and unofficial.
- No warranty: Use at your own risk.
- It is for my personal use.
- Trademarks: id Software, Bethesda, and Quake are a registered trademark of there respective owners. All rights reserved by their respective parties.
