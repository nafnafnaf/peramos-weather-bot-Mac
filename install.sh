#!/bin/bash

# Peramos Weather Bot - Automated Installation Script
# This script clones the repository and sets up the bot with Docker

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/YOUR_USERNAME/peramos-weather-bot.git"
REPO_NAME="peramos-weather-bot"
DEFAULT_TOKEN="your_bot_token_here"

# Functions
print_banner() {
    echo -e "${BLUE}"
    echo "================================================"
    echo "   Peramos Weather Bot - Docker Installer"
    echo "================================================"
    echo -e "${NC}"
}

check_requirements() {
    echo -e "${YELLOW}📋 Checking requirements...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker is not installed${NC}"
        echo "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker found${NC}"
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ Docker Compose is not installed${NC}"
        echo "Please install Docker Compose first"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker Compose found${NC}"
    
    # Check Git
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git is not installed${NC}"
        echo "Please install Git first"
        exit 1
    fi
    echo -e "${GREEN}✓ Git found${NC}"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker daemon is not running${NC}"
        echo "Please start Docker and try again"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker daemon is running${NC}"
}

clone_repository() {
    echo -e "\n${YELLOW}📦 Cloning repository...${NC}"
    
    # Check if directory already exists
    if [ -d "$REPO_NAME" ]; then
        echo -e "${YELLOW}Directory $REPO_NAME already exists${NC}"
        read -p "Do you want to remove it and clone fresh? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$REPO_NAME"
            git clone "$REPO_URL"
        else
            echo "Using existing directory"
        fi
    else
        git clone "$REPO_URL"
    fi
    
    cd "$REPO_NAME"
    echo -e "${GREEN}✓ Repository cloned${NC}"
}

setup_environment() {
    echo -e "\n${YELLOW}🔧 Setting up environment...${NC}"
    
    # Check if .env exists
    if [ -f .env ]; then
        echo -e "${YELLOW}.env file already exists${NC}"
        read -p "Do you want to reconfigure it? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Get bot token from user
    echo -e "\n${BLUE}Please enter your Telegram Bot Token${NC}"
    echo "Get it from @BotFather on Telegram"
    read -p "Bot Token (press Enter to use placeholder): " BOT_TOKEN
    
    if [ -z "$BOT_TOKEN" ]; then
        BOT_TOKEN="$DEFAULT_TOKEN"
        echo -e "${YELLOW}⚠️  Using placeholder token. Bot won't work until you set a real token!${NC}"
    fi
    
    # Create .env file
    echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" > .env
    echo -e "${GREEN}✓ Environment configured${NC}"
}

build_and_run() {
    echo -e "\n${YELLOW}🔨 Building Docker image...${NC}"
    
    # Stop and remove existing container if exists
    if docker ps -a | grep -q weather-bot; then
        echo "Stopping existing container..."
        docker stop weather-bot 2>/dev/null || true
        docker rm weather-bot 2>/dev/null || true
    fi
    
    # Build image
    docker-compose build --no-cache
    
    echo -e "\n${YELLOW}🚀 Starting bot...${NC}"
    docker-compose up -d
    
    # Wait for container to start
    sleep 3
    
    # Check if container is running
    if docker ps | grep -q weather-bot; then
        echo -e "${GREEN}✓ Bot is running!${NC}"
    else
        echo -e "${RED}❌ Bot failed to start${NC}"
        echo "Check logs with: docker logs weather-bot"
        exit 1
    fi
}

show_status() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${GREEN}✅ Installation Complete!${NC}"
    echo -e "${BLUE}================================================${NC}"
    
    # Show container status
    echo -e "\n${YELLOW}📊 Container Status:${NC}"
    docker ps --filter name=weather-bot --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
    
    # Show initial logs
    echo -e "\n${YELLOW}📝 Initial Logs:${NC}"
    docker logs weather-bot --tail 10
    
    # Show resource usage
    echo -e "\n${YELLOW}💾 Resource Usage:${NC}"
    docker stats weather-bot --no-stream
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo "  View logs:        docker logs -f weather-bot"
    echo "  Check status:     docker ps | grep weather-bot"
    echo "  View resources:   docker stats weather-bot"
    echo "  Stop bot:         docker-compose down"
    echo "  Restart bot:      docker-compose restart"
    echo "  Update token:     nano .env && docker-compose restart"
    
    if [ "$BOT_TOKEN" == "$DEFAULT_TOKEN" ]; then
        echo -e "\n${RED}⚠️  IMPORTANT: Bot is using placeholder token!${NC}"
        echo "To make it work:"
        echo "1. Get a real token from @BotFather on Telegram"
        echo "2. Run: nano .env"
        echo "3. Replace the token and save"
        echo "4. Run: docker-compose restart"
    else
        echo -e "\n${GREEN}🤖 Your bot should now be responding on Telegram!${NC}"
        echo "Send a message to your bot to test it."
    fi
}

cleanup_on_error() {
    echo -e "\n${RED}Installation failed. Cleaning up...${NC}"
    cd ..
    rm -rf "$REPO_NAME" 2>/dev/null || true
    docker stop weather-bot 2>/dev/null || true
    docker rm weather-bot 2>/dev/null || true
}

# Main installation flow
main() {
    clear
    print_banner
    
    # Set error trap
    trap cleanup_on_error ERR
    
    # Run installation steps
    check_requirements
    clone_repository
    setup_environment
    build_and_run
    show_status
    
    # Remove error trap
    trap - ERR
}

# Run main function
main