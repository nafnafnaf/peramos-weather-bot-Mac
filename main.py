import os
import sys
import time
import logging
from datetime import datetime
import telepot
from telepot.loop import MessageLoop
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
from bs4 import BeautifulSoup as soup
from time import gmtime, strftime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# PERAMOS BOT Configuration
# IMPORTANT: Use environment variable for token (never hardcode in production!)
TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN', '7162260320:AAEkpBMf8xfEgGQHSXSkyqd0QTtcej7SrmQ')
WEATHER_URL = "http://penteli.meteo.gr/stations/neaperamos/"
USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
SCRAPE_TIMEOUT = 10  # seconds
RETRY_ATTEMPTS = 3
RETRY_DELAY = 2  # seconds

def scrape_weather_data(retries=RETRY_ATTEMPTS):
    """
    Scrape weather data from the Penteli weather station.
    Includes retry logic and better error handling.
    """
    for attempt in range(retries):
        try:
            headers = {'User-Agent': USER_AGENT}
            req = Request(WEATHER_URL, headers=headers)
            
            # Add timeout to prevent hanging
            response = urlopen(req, timeout=SCRAPE_TIMEOUT)
            page = response.read()
            response.close()
            
            # Parse the HTML
            page_soup = soup(page, "html.parser")
            
            # Extract text labels
            text_labels = []
            for tag in page_soup.find_all("div", {"class": "lleft"}):
                # Clean up text, removing non-ASCII characters
                label = tag.get_text(strip=True).encode('ascii', errors='ignore').decode()
                if label:  # Only add non-empty labels
                    text_labels.append(label)
            
            # Extract values
            values = []
            for tag in page_soup.find_all("div", {"class": "lright"}):
                value = tag.get_text(strip=True)
                if value:  # Only add non-empty values
                    values.append(value)
            
            # Check if we got data
            if not text_labels or not values:
                logger.warning(f"No data found on attempt {attempt + 1}")
                if attempt < retries - 1:
                    time.sleep(RETRY_DELAY)
                    continue
                return "⚠️ No weather data available at the moment. Please try again later."
            
            # Format the response
            result = "🌤️ **Weather Station: Nea Peramos**\n"
            result += "=" * 30 + "\n"
            
            # Combine labels and values
            for label, value in zip(text_labels, values):
                result += f"📊 {label}: {value}\n"
            
            # Add timestamp and source
            result += "=" * 30 + "\n"
            result += f"🕐 Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
            result += "📡 Source: MacMiniM4"
            
            return result
            
        except HTTPError as e:
            logger.error(f"HTTP Error on attempt {attempt + 1}: {e.code} - {e.reason}")
        except URLError as e:
            logger.error(f"URL Error on attempt {attempt + 1}: {e.reason}")
        except Exception as e:
            logger.error(f"Unexpected error on attempt {attempt + 1}: {str(e)}")
        
        # Wait before retry
        if attempt < retries - 1:
            time.sleep(RETRY_DELAY)
    
    return "❌ Unable to fetch weather data after multiple attempts. Please try again later."

def handle_message(msg):
    """
    Handle incoming Telegram messages.
    """
    try:
        content_type, chat_type, chat_id = telepot.glance(msg)
        
        # Log incoming message
        logger.info(f"Message received - Type: {content_type}, Chat: {chat_type}, "
                   f"ID: {chat_id}, Time: {strftime('%Y-%m-%d %H:%M:%S')}")
        
        if content_type == 'text':
            message_text = msg.get('text', '').lower()
            
            # Handle different commands
            if message_text == '/start':
                welcome_msg = (
                    "👋 Welcome to Nea Peramos Weather Bot!\n\n"
                    "Available commands:\n"
                    "/weather - Get current weather data\n"
                    "/help - Show this help message\n"
                    "/about - About this bot"
                )
                bot.sendMessage(chat_id, welcome_msg)
            
            elif message_text == '/help':
                help_msg = (
                    "📚 **Help**\n\n"
                    "Simply send any message or use:\n"
                    "/weather - to get the current weather data\n"
                    "/about - to learn more about this bot"
                )
                bot.sendMessage(chat_id, help_msg)
            
            elif message_text == '/about':
                about_msg = (
                    "ℹ️ **About**\n\n"
                    "This bot provides real-time weather data from "
                    "the Nea Peramos weather station.\n\n"
                    "Data source: penteli.meteo.gr"
                )
                bot.sendMessage(chat_id, about_msg)
            
            else:
                # Default action: send weather data
                bot.sendMessage(chat_id, "🔄 Fetching weather data...")
                weather_data = scrape_weather_data()
                bot.sendMessage(chat_id, weather_data, parse_mode='Markdown')
        
        else:
            # Handle non-text messages
            bot.sendMessage(chat_id, "⚠️ Please send a text message to get weather data.")
            
    except Exception as e:
        logger.error(f"Error handling message: {str(e)}")
        try:
            bot.sendMessage(chat_id, "❌ An error occurred. Please try again.")
        except:
            pass

def main():
    """
    Main function to initialize and run the bot.
    """
    global bot
    
    try:
        # Initialize bot
        bot = telepot.Bot(TOKEN)
        
        # Get bot info
        bot_info = bot.getMe()
        logger.info(f"Bot started: @{bot_info['username']}")
        
        # Start message loop
        MessageLoop(bot, handle_message).run_as_thread()
        logger.info('Bot is listening for messages...')
        
        # Keep the program running
        while True:
            time.sleep(120)
            # Optional: Add periodic health check
            if int(time.time()) % 3600 == 0:  # Every hour
                logger.info("Bot is still running...")
                
    except KeyboardInterrupt:
        logger.info("Bot stopped by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Fatal error: {str(e)}")
        sys.exit(1)

if __name__ == '__main__':
    main()