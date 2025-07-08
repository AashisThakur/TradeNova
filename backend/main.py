import os
import re
import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from py5paisa import FivePaisaClient
from bs4 import BeautifulSoup

# Load credentials
load_dotenv()

creds = {
    "APP_SOURCE": '',
    "APP_NAME": '',
    "USER_ID": '',
    "PASSWORD": '',
    "USER_KEY": '',
    "ENCRYPTION_KEY": '',
}

client = FivePaisaClient(cred=creds)
client.get_oauth_session("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjU2Nzc1NTE2Iiwicm9sZSI6InBpQkFDdk1UcHpFTG5RbHBsMmhRYmNZSUQzbFZKejhKIiwiU3RhdGUiOiIiLCJuYmYiOjE3NTE5NzAxNjgsImV4cCI6MTc1MTk3Mzc2OCwiaWF0IjoxNzUxOTcwMTY4fQ.0ss4k0gm324I-RzPnk1ahzJktxx0Tn7vFCSVBmFMvtc")

# FastAPI app setup
app = FastAPI()

# Enable CORS for local Flutter dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # change for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "OK"}

@app.get("/holdings")
def get_holdings():
    try:
        return client.holdings()
    except Exception as e:
        return {"error": str(e)}

@app.get("/option-chain")
def get_option_chain():
    try:
        expiry_data = client.get_expiry("N", "NIFTY")
        expiry_list = expiry_data.get("Expiry", [])

        if not expiry_list:
            return {"error": "No expiry dates found."}

        expiry_ts_str = expiry_list[0]["ExpiryDate"]
        match = re.search(r"\d+", expiry_ts_str)
        if not match:
            return {"error": "Failed to parse expiry timestamp."}

        expiry_ts = int(match.group(0))
        return client.get_option_chain("N", "NIFTY", expiry_ts)
    except Exception as e:
        return {"error": str(e)}

@app.get("/announcements")
def announcements():
    url = "https://www.5paisa.com/announcements"
    resp = requests.get(url)
    soup = BeautifulSoup(resp.content, "html.parser")
    items = []
    for div in soup.select(".announcement-card"):
        title = div.select_one(".title").get_text(strip=True)
        date = div.select_one(".date").get_text(strip=True)
        items.append({"title": title, "date": date})
    return {"announcements": items}
# import datetime
# import os
# import requests
# from dotenv import load_dotenv
# from py5paisa import FivePaisaClient

# # Load .env
# load_dotenv()

# creds = {
#     "APP_SOURCE": '25644',
#     "APP_NAME": '5P56775516',
#     "USER_ID": 'pptiHbdZRTm',
#     "PASSWORD": '7IxEptH2XZx',
#     "USER_KEY": 'piBACvMTpzELnQlpl2hQbcYID3lVJz8J',
#     "ENCRYPTION_KEY": 'WjoXMxzDQvaDjxwrpniVQigIRtrXkI7Y',
# }

# client = FivePaisaClient(cred=creds)
# # client.Login_check()
# client.get_oauth_session('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjU2Nzc1NTE2Iiwicm9sZSI6InBpQkFDdk1UcHpFTG5RbHBsMmhRYmNZSUQzbFZKejhKIiwiU3RhdGUiOiIiLCJuYmYiOjE3NTE5NjU0MzksImV4cCI6MTc1MTk2OTAzOSwiaWF0IjoxNzUxOTY1NDM5fQ.kGyZLcqogaQPDETa7TC0HOLpBTYpAA2G6uFNIZt3vis')

# # After successful authentication, you should get a `Logged in!!` message in console

# holdings = client.holdings()
# print('client access ',client.get_access_token())

# #Login with Access Token
# client.set_access_token('accessToken','clientCode')
# #Function to fetch access token after successful login
# # print("✅ Holdings:\n", holdings)

# expiries_data = client.get_expiry("N", "NIFTY")
# expiry_list = expiries_data.get("Expiry", [])

# # Pick the first expiry
# # print(expiry_list)
# if expiry_list:
#     expiry_ts = expiry_list[0]["ExpiryDate"]
    
#     # Extract timestamp from "/Date(1721251200000)/"
#     import re
#     match = re.search(r"\d+", expiry_ts)
#     if match:
#         expiry_timestamp = int(match.group(0))
#         # print("📅 Expiry Timestamp (ms):", expiry_timestamp)

#         option_chain = client.get_option_chain("N", "NIFTY", expiry_timestamp)
#         # print("📈 Option Chain:\n", option_chain)
#     else:
#         print("❌ Failed to parse expiry timestamp.")
# else:
#     print("❌ No expiry dates found.")
