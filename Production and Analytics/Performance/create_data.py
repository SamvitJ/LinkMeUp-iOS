import json
import httplib

PARSE_APP_ID = "bHKPHXkC9AlKEuga4GR1rTUF4jlKjd8Mr9SwKosa"
PARSE_API_KEY = "oUDTNZ7diFy7w8i82GZRPPHwOE4olrUErExB5xVM"

def createUsersAndLinks(number_users, links_per_user):

    connection = httplib.HTTPSConnection('api.parse.com', 443)
    connection.connect()

    # create users and links
    for x in range(0, number_users):

        # create user
        connection.request('POST', '/1/classes/_User', json.dumps({
            "username": str(x),
            "password": str(x)
        }), {
            "X-Parse-Application-Id": PARSE_APP_ID,
            "X-Parse-REST-API-Key": PARSE_API_KEY,
            "Content-Type": "applications/json"
        })
        response_user = connection.getresponse()
        result_user = json.loads(response_user.read())

        print result_user

        # create request list
        request_list = []

        for y in range(0, links_per_user):

            request = {
                "method": "POST",
                "path": "/1/classes/Link",
                "body": {
                    "title": "%s-%u" % (result_user.get('objectId', None), y),
                    "sender": {
                        "__type": "Pointer",
                        "className": "_User",
                        "objectId": result_user.get('objectId', None)
                    }
                }
            }

            request_list.append(request)

        # create links
        connection.request('POST', '/1/batch', json.dumps({
            "requests": request_list
        }), {
            "X-Parse-Application-Id": PARSE_APP_ID,
            "X-Parse-REST-API-Key": PARSE_API_KEY,
            "Content-Type": "application/json"
        })

        response_links = connection.getresponse()
        result_links = json.loads(response_links.read())

        # for link in result_links
        #     print link


# import requests
# from requests_oauthlib import OAuth1

# for x in range(0, 10):

#     data = json.dumps({ 
#         'username': str(x),
#         'password': str(x)
#     })

#     myauth = OAuth1('oUDTNZ7diFy7w8i82GZRPPHwOE4olrUErExB5xVM', 
#         client_secret='bHKPHXkC9AlKEuga4GR1rTUF4jlKjd8Mr9SwKosa')
#         # signature_type='query'

#     # r = requests.get('http://api.parse.com/1/classes/_User/TZPK3E6maI', auth=myauth)
#     # r = requests.post('http://api.parse.com/1/classes/_User', json=data, auth=myauth)
#     r = requests.request('POST', 'http://api.parse.com/1/classes/_User', data=data, auth=myauth)
#     print r.text
