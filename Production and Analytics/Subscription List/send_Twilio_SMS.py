from twilio.rest import TwilioRestClient 
  
ACCOUNT_SID = ""
AUTH_TOKEN = ""
 
client = TwilioRestClient(ACCOUNT_SID, AUTH_TOKEN) 
 
with open("Mobile Numbers/mobile_numbers_usa.txt", "r") as usa_numbers_file:

    usa_numbers_list = usa_numbers_file.read().splitlines()

    for usa_number in usa_numbers_list:
        print usa_number

        message = client.messages.create (
            to = usa_number, 
            from_ = "", 
            body = "LinkMeUp for Android is now live in the Google Play Store!\n\n"
                "To promote the launch, we're giving away Amazon gift cards to users who refer their friends to LinkMeUp.\n\n"
                "For the first friend who gets LinkMeUp, we'll email you a $5 gift card. For every friend after that, we'll add $2 to the value of the card.\n\n"
                "To participate, just send us an email at contest@linkmeupmessenger.com with the names of your friends who got the app. We'll reply with a link to your card :) \n\n"
                "This info is also on our Facebook page at www.facebook.com/linkmessaging. Good luck!\n",
        )

        print message

