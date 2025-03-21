#!/bin/bash

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Dope ASCII Art
echo -e "${PURPLE}"
cat << "EOF"
🔥 LLM TUNNEL EXPOSER 🔥
█▄░█ █▀▀ █▀█ █▀█ █▄▀   ▀█▀ █░█ █▄░█ █▄░█ █▀▀ █░░
█░▀█ █▄█ █▀▄ █▄█ █░█   ░█░ █▄█ █░▀█ █░▀█ ██▄ █▄▄
EOF
echo -e "${NC}"

# Function to print section header
print_header() {
    echo -e "\n${PURPLE}${BOLD}[+] $1 ${NC}\n"
}

# Function to print step
print_step() {
    echo -e "${CYAN}[*] $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}[✗] $1${NC}"
    exit 1
}

# Function to check ngrok installation
check_ngrok() {
    print_step "Checking ngrok setup..."
    
    if ! command -v ngrok &> /dev/null; then
        print_step "ngrok not found, installing..."
        
        # Detect architecture
        ARCH=$(uname -m)
        case $ARCH in
            x86_64)
                NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
                ;;
            aarch64)
                NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz"
                ;;
            *)
                print_error "Unsupported architecture: $ARCH"
                ;;
        esac
        
        # Download and install ngrok
        curl -Lo ngrok.tgz $NGROK_URL
        sudo tar xvzf ngrok.tgz -C /usr/local/bin
        rm ngrok.tgz
        
        print_success "ngrok installed"
    else
        print_success "ngrok already installed"
    fi
}

# Function to check environment
check_environment() {
    print_step "Checking environment..."
    
    # Load environment variables
    if [ -f ".env.local" ]; then
        source .env.local
    else
        print_error ".env.local not found! Run setup_environment.sh first"
    fi
    
    # Check ngrok token
    if [ -z "$NGROK_AUTH_TOKEN" ]; then
        echo -e "${YELLOW}No ngrok auth token found!${NC}"
        echo -e "${CYAN}Enter your ngrok auth token (from https://dashboard.ngrok.com):${NC}"
        read -r token
        
        if [ -z "$token" ]; then
            print_error "Token required to expose server"
        fi
        
        echo "NGROK_AUTH_TOKEN=$token" >> .env.local
        NGROK_AUTH_TOKEN=$token
    fi
    
    print_success "Environment checked"
}

# Function to configure ngrok
configure_ngrok() {
    print_step "Configuring ngrok..."
    
    # Create ngrok config directory
    mkdir -p ~/.ngrok2
    
    # Create ngrok config
    cat > ~/.ngrok2/ngrok.yml << EOF
authtoken: $NGROK_AUTH_TOKEN
version: 2
region: us
tunnels:
  api:
    addr: 8000
    proto: http
    inspect: false
    bind_tls: true
  web:
    addr: 3000
    proto: http
    inspect: false
    bind_tls: true
EOF
    
    # Set permissions
    chmod 600 ~/.ngrok2/ngrok.yml
    
    print_success "ngrok configured"
}

# Function to check services
check_services() {
    print_step "Checking if required services are running..."
    
    # Check API server
    if ! curl -s http://localhost:8000/health &>/dev/null; then
        print_error "API server not running! Start it with ./server.sh first"
    fi
    
    # Check bolt.diy
    if ! curl -s http://localhost:3000 &>/dev/null; then
        print_error "bolt.diy not running! Start it with ./launch_bolt.sh first"
    fi
    
    print_success "All services are running"
}

# Function to start tunnels
start_tunnels() {
    print_header "STARTING NGROK TUNNELS"
    
    # Create logs directory
    mkdir -p logs
    
    # Kill existing ngrok processes
    pkill -f ngrok
    
    # Start API tunnel
    print_step "Starting API tunnel..."
    ngrok http --log=stdout 8000 > logs/ngrok_api.log &
    
    # Start Web tunnel
    print_step "Starting Web tunnel..."
    ngrok http --log=stdout 3000 > logs/ngrok_web.log &
    
    # Wait for tunnels to establish
    sleep 5
    
    # Get tunnel URLs
    API_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
    WEB_URL=$(curl -s http://localhost:4041/api/tunnels | jq -r '.tunnels[0].public_url')
    
    if [ -z "$API_URL" ] || [ -z "$WEB_URL" ]; then
        print_error "Failed to get tunnel URLs"
    fi
    
    print_success "Tunnels established"
    
    # Update .env.local with new URLs
    sed -i "s#OPENAI_LIKE_API_BASE_URL=.*#OPENAI_LIKE_API_BASE_URL=$API_URL#g" .env.local
    
    print_header "TUNNEL INFORMATION"
    echo -e "${YELLOW}API Server:${NC} $API_URL"
    echo -e "${YELLOW}Web Interface:${NC} $WEB_URL"
    echo -e "\n${GREEN}Your LLM server is now exposed to the internet! 🌍${NC}"
    
    # Save tunnel info
    echo "{\"api_url\": \"$API_URL\", \"web_url\": \"$WEB_URL\"}" > tunnels.json
}

# Function to create tunnel management scripts
create_management_scripts() {
    print_step "Creating management scripts..."
    
    # Create stop script
    cat > stop_tunnels.sh << 'EOF'
#!/bin/bash
pkill -f ngrok
rm -f tunnels.json
echo "Tunnels stopped"
EOF
    chmod +x stop_tunnels.sh
    
    # Create restart script
    cat > restart_tunnels.sh << 'EOF'
#!/bin/bash
./stop_tunnels.sh
sleep 2
./expose.sh
EOF
    chmod +x restart_tunnels.sh
    
    print_success "Management scripts created"
}

# Function to monitor tunnels
monitor_tunnels() {
    print_step "Starting tunnel monitor..."
    
    while true; do
        if ! curl -s http://localhost:4040/status &>/dev/null; then
            print_error "API tunnel died! Check logs/ngrok_api.log"
        fi
        if ! curl -s http://localhost:4041/status &>/dev/null; then
            print_error "Web tunnel died! Check logs/ngrok_web.log"
        fi
        sleep 5
    done &
    
    MONITOR_PID=$!
    echo $MONITOR_PID > tunnel_monitor.pid
}

# Main execution
print_header "EXPOSING LLM SERVER"

# Run checks
check_ngrok
check_environment
configure_ngrok
check_services

# Create management scripts
create_management_scripts

# Start tunnels
start_tunnels

# Start monitoring
monitor_tunnels

# Monitor logs
print_step "Showing tunnel logs (Ctrl+C to exit)..."
tail -f logs/ngrok_*.log