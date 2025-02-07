# Libra Framework Testnet in a Bottle

This repository contains Docker configuration for running a local 3-node Libra testnet. The setup includes three validator nodes: Alice, Bob, and Carol.

## Prerequisites

### Installing Docker on Ubuntu

We provide a script to install Docker on Ubuntu. Simply run:

```bash
sudo ./docker/install_docker.sh
```

After installation, configure your user to run Docker without sudo:

```bash
sudo usermod -aG docker $USER
```

**Important**: Log out and log back in for the group changes to take effect.

### Verify Docker Installation

Verify Docker is working correctly:

```bash
docker run hello-world
```

## Running the Testnet

1. Clone this repository:
```bash
$HOME
git clone https://github.com/0LNetworkCommunity/libra-framework
cd $HOME/libra-framework
```

2. Start the testnet using Docker Compose:
```bash
cd $HOME/libra-framework/docker
docker compose up -d
docker compose logs -f --tail 100
```

### Build Options

The testnet supports two build modes:

1. **Fresh Build** (Default): Completely clean build that clones a fresh copy of the repository
   - Enabled by default with `FRESH_BUILD=true` for Alice
   - Use this when switching between different repositories or branches
   - Ensures you're building from the correct source by removing any existing libra-framework directory
   - Required when changing between different forks or branches (e.g., switching from one GitHub organization to another)

2. **Cached Build**: Reuses existing source code
   - Set `FRESH_BUILD=false` in docker-compose.yml for Alice
   - Keeps the existing repository clone and build artifacts
   - Useful when working consistently with the same branch/fork
   - Significantly faster for development when not switching branches

To switch between modes, modify the `FRESH_BUILD` environment variable for Alice in `docker-compose.yml`:
```yaml
  alice:
    environment:
      - FRESH_BUILD=false  # Set to false to keep existing repository clone
```

### What Happens When You Start the Testnet

1. Three containers will be created: Alice, Bob, and Carol
2. Alice will:
   - Clean up previous build if `FRESH_BUILD=true`
   - Perform the initial build of the Libra Framework (this may take several minutes)
   - Signal completion to other nodes
3. Bob and Carol will:
   - Wait for Alice's build to complete
   - Use the shared build artifacts
4. All nodes will start and form the testnet

### Container Details

- **Alice**: The primary builder node
  - Ports: 8180:8080 (API), 9201:9101 (Metrics)
  - Controls the build process
  - Acts as the first validator

- **Bob**: Secondary validator node
  - Waits for Alice's build
  - Acts as the second validator

- **Carol**: Tertiary validator node
  - Waits for Alice's build
  - Acts as the third validator

### Shared Resources

The setup uses Docker volumes to share resources between containers:
- `cargo-cache`: Shared Rust/Cargo cache to avoid rebuilding dependencies
- `build-signal`: Coordinates build completion between nodes

## Monitoring the Network

You can monitor each node's logs in real-time:

```bash
# View compose logs
docker compose logs -f --tail 100

# View specific node logs
docker logs -f alice --tail 100
docker logs -f bob --tail 100
docker logs -f carol --tail 100
```

### Real-time Network Status

For a quick overview of the testnet status, use the provided watch script:

```bash
# Updates every second
watch -n1 ./watch_testnet.sh
```

This will show you a real-time view of the network's status, including node health and synchronization state.

## Stopping the Testnet

To stop the testnet:

```bash
cd $HOME/libra-framework/docker
docker compose down
```

To stop and remove all data (including cached builds):
```bash
cd $HOME/libra-framework/docker
docker compose down -v
```

## Troubleshooting

1. If you see permission errors when running Docker commands, ensure you've logged out and back in after adding your user to the docker group.

2. If nodes are not connecting:
   - Ensure no other services are using the required ports
   - Check the logs for specific error messages
   - Try restarting the network with:
   ```bash 
   cd $HOME/libra-framework/docker
   docker compose down && docker compose up
   ```

3. If the build seems stuck:
   - Check Alice's logs specifically: 
   ```bash 
   cd $HOME/libra-framework/docker
   docker logs -f alice --tail 100
   ```
   - The initial build can take several minutes depending on your system
   - Verify the build-signal volume is working properly

4. For build issues:
   - If the build seems corrupted, ensure Alice has `FRESH_BUILD=true`
   - Try a complete reset:
     ```bash
     cd $HOME/libra-framework/docker
     docker compose down -v
     docker compose up --force-recreate
     ```

5. Network connectivity issues:
   - Ensure all nodes can resolve each other by hostname
   - Check if the libra_network is created properly
   - Verify the subnet configuration (10.0.0.0/24) is not conflicting with your local network
