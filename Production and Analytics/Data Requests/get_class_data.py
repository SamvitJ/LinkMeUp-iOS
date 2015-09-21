import json
import httplib, urllib

def returnClassData (parse_class_name):

    skip = 0
    limit = 1000

    all_data = []

    while True:

        # print skip

        connection = httplib.HTTPSConnection('api.parse.com', 443)
        params = urllib.urlencode({"limit":limit,"skip":skip})
        connection.connect()
        connection.request('GET', '/1/classes/%s?%s' % (parse_class_name, params), '', {
               "X-Parse-Application-Id": "",
               "X-Parse-REST-API-Key": ""
             })
        result = json.loads(connection.getresponse().read())

        request_data = result.get('results', None)

        if not request_data:
            break

        all_data.extend(request_data)
        skip = skip + limit

    return all_data

