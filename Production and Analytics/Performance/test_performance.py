import json
import httplib
import urllib
import time

from create_data import createUsersAndLinks


PARSE_APP_ID = "bHKPHXkC9AlKEuga4GR1rTUF4jlKjd8Mr9SwKosa"
PARSE_API_KEY = "oUDTNZ7diFy7w8i82GZRPPHwOE4olrUErExB5xVM"


# create data
number_users = 10000
links_per_user = 10
createUsersAndLinks(number_users, links_per_user)


# retrieve links for user

# initialize
cum_time_req = 0
cum_time_resp = 0
iterations = 10

connection = httplib.HTTPSConnection('api.parse.com', 443)
connection.connect()

# query for user
for x in range(0, iterations):

    # get objectId for user with username 'x'
    params = urllib.urlencode({"where":json.dumps({
        "username": str(x)
    })})

    connection.request('GET', '/1/classes/_User?%s' % params, '', {
        "X-Parse-Application-Id": PARSE_APP_ID,
        "X-Parse-REST-API-Key": PARSE_API_KEY,
        "Content-Type": "application/json"
    })
    response_users = connection.getresponse()
    result_users = json.loads(response_users.read())

    user = result_users.get('results', None)[0]
    user_objectId = user.get('objectId', None)

    # print user

    # get links for user
    params = urllib.urlencode({"where":json.dumps({
        "sender": {
            "__type": "Pointer",
            "className": "_User",
            "objectId": user_objectId
        }
    })})

    # start timer
    start = time.time()
    print "Start: %f" % start

    # request
    connection.request('GET', '/1/classes/Link?%s' % params, '', {
        "X-Parse-Application-Id": PARSE_APP_ID,
        "X-Parse-REST-API-Key": PARSE_API_KEY,
        "Content-Type": "application/json"
    })

    # request time
    time_request = time.time()
    print "Request: %f" % time_request

    # response
    response_links = connection.getresponse()

    # response time
    time_response = time.time()
    print "Response: %f" % time_response

    # link data
    result_links = json.loads(response_links.read())
    links = result_links.get('results', None)

    # for link in links:
    #     print link

    net_time_req = time_request - start
    net_time_resp = time_response - start

    cum_time_req += net_time_req
    cum_time_resp += net_time_resp

    print "Response time %f" % net_time_resp


# log statistics
print "------------------"
print "Average request time %f" % (cum_time_req / iterations)
print "Average response time %f" % (cum_time_resp / iterations)





