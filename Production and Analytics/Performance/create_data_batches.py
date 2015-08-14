import json
import httplib

PARSE_APP_ID = "bHKPHXkC9AlKEuga4GR1rTUF4jlKjd8Mr9SwKosa"
PARSE_API_KEY = "oUDTNZ7diFy7w8i82GZRPPHwOE4olrUErExB5xVM"

def createUsersAndLinks(number_users, links_per_user):

    connection = httplib.HTTPSConnection('api.parse.com', 443)
    connection.connect()

    # batch limit
    batch_limit = 50

    for batch in range(0, number_users/batch_limit):

        # user request list
        user_request_list = []

        # create user request list for batch
        for x in range(batch * batch_limit, (batch + 1) * batch_limit):

            # user request list
            user_request = {
                "method": "POST",
                "path": "/1/classes/_User",
                "body": {
                    "username": str(x),
                    "password": str(x)
                }
            }

            user_request_list.append(user_request)

        # print user_request_list

        # create users
        connection.request('POST', '/1/batch', json.dumps({
            "requests": user_request_list
        }), {
            "X-Parse-Application-Id": PARSE_APP_ID,
            "X-Parse-REST-API-Key": PARSE_API_KEY,
            "Content-Type": "application/json"
        })
        response_users = connection.getresponse()
        result_users = json.loads(response_users.read())

        print result_users

        users = result_users.get('results', None)

        for user in users:
            print user

        # create link request lists
        for user in users:

            link_request_list = []

            user_objectId = user.get('objectId', None)

            for y in range(0, links_per_user):

                link_request = {
                    "method": "POST",
                    "path": "/1/classes/Link",
                    "body": {
                        "title": "%s-%u" % (user_objectId, y),
                        "sender": {
                            "__type": "Pointer",
                            "className": "_User",
                            "objectId": user_objectId
                        }
                    }
                }

                link_request_list.append(link_request)

            # create links
            connection.request('POST', '/1/batch', json.dumps({
                "requests": link_request_list
            }), {
                "X-Parse-Application-Id": PARSE_APP_ID,
                "X-Parse-REST-API-Key": PARSE_API_KEY,
                "Content-Type": "application/json"
            })
            response_links = connection.getresponse()
            result_links = json.loads(response_links.read())
            links = result_links.get('results', None)

            # for link in links
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
