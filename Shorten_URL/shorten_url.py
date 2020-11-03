import csv
import urllib.request
import sys
import urllib.parse
from urllib.parse import unquote_plus
import time

def tiny_url(url):
    apiurl = "https://tinyurl.com/api-create.php?url="
    tinyurl = urllib.request.urlopen(apiurl + url).read()
    return tinyurl.decode("utf-8")



# place csv filename exported from EventEngine
with open('test-teams.csv', mode='r') as csvfile:

  rows = csv.reader(csvfile, delimiter=',')
  next(rows)

  timestr = time.strftime("%Y%m%d-%H%M%S")
  sys.stdout = open("event_engine_shortenurl_" + timestr + ".txt", "w")

  for row in rows:
  	#print(row[5])
  	shorten_url = tiny_url(row[5])
  	print(shorten_url)

  sys.stdout.close()

