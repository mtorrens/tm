#!/usr/bin/python
# -*- coding: utf-8 -*-
################################################################################
# TED Talk scraper
################################################################################
# Script : ted_scrapper.py
################################################################################

################################################################################
# Libraries
import urllib2, urllib
import urlparse  
import collections
import time, random
from lxml import html  

# Set the root weblink and initialise the counter
ted_root = 'http://www.ted.com/talks?page=1'
adder = 0

# Keep track of the links to be attempted
queue_links = collections.deque()  
queue_links.append(ted_root)

# Keep track of the processed URLS
proc_links = set()  
proc_links.add(ted_root)

# Some general expressions we will need
xpath1 = '//span[@class="talk-transcript__fragment"]/text()'
xpath2 = '//*[@id="shoji"]/div[2]/div/div[2]/div/div/div/div[2]/div[1]/div/div[2]/div/div[2]/h4[2]/a/text()'
xpath3 = '//h4[@class="h12 talk-link__speaker"]/text()'
xpath4 = '//span[@class="meta__val"]/text()'
xpath5 = '//a[@class=""]/@href'
xpath6 = '//span[@class="talk-sharing__value"]/text()'
xpath7 = '//a[@class="l3 talk-topics__link ga-link"]/text()'
#xpath8 = '//span[@class="player-hero__meta__label"]/text()'
################################################################################

################################################################################
def scrap_talk(url):
################################################################################
  # Import global elements
  global adder, xpath1, xpath2, xpath3, xpath4, xpath5, xpath6, xpath7
  #global adder, xpath1, xpath2, xpath3, xpath4, xpath5, xpath6, xpath7, xpath8
  
  # Intend of scrapping
  try:
    # Delay execution
    time.sleep(random.randint(0, 1))
    #time.sleep(random.randint(1, 2))
    fetched = urllib2.urlopen(url)
    content = fetched.read()
    body = html.fromstring(content)
    is_talk = body.xpath(xpath1)
    
    # When the element inspected is a talk
    if is_talk:
      # Begin with title and speaker
      end_text = ''
      title = body.xpath(xpath2)[0].replace('\n', '')
      speaker = body.xpath(xpath3)[0]
      
      # Trye to obtain other attributes: date, tags, number of shares
      ted_date = body.xpath(xpath4)[0].replace('\n', '')
      tags = body.xpath(xpath4)[1].replace('\n', '')
      mother_url = body.xpath(xpath5)[0]
      try:
        # Investigate the full page of the talk for more info
        mother_fetched = urllib2.urlopen(mother_url)
        mother_content = mother_fetched.read()
        mother_body = html.fromstring(mother_content)
        
        # Number of shares
        n_views = mother_body.xpath(xpath6)
        if n_views:
          n_views = n_views[0].replace('\n', '')
          n_views = n_views.replace(',', '')
          #n_views = int(n_views.replace(',', ''))
        else:
          n_views = '0'
        
        # Topics
        topics = mother_body.xpath(xpath7)
        if topics:
          topics_list = ''
          for i in range(len(topics)):
            topics_list += topics[i].replace('\n', '') + ', '
          topics_list = topics_list[:-2]
        else:
          topics_list = ''
        
        ## Alternative date
        #new_date = mother_body.xpath(xpath8)
        
      except urllib2.HTTPError:
        n_views = '0'
        topics_list = ''
      
      #end_text += 'Title: ' + title + '\n' + 'Speaker: ' + speaker + '\n\n'
      end_text += 'Title: ' + title + '\n' + 'Speaker: ' + speaker + '\n'
      end_text += 'Date: ' + ted_date + '\n' + 'Tags: ' + tags + '\n'
      end_text += 'Shares: ' + n_views + '\nTopics: ' + topics_list + '\n'
      end_text += 'Original URL: ' + mother_url + '\n\n'
      
      # The HTML contains the text stripped in various elements
      end_talk = ''
      for txt in is_talk:
        end_talk += txt + ' '
      
      # When all chunks are united, we close the talk
      end_text += end_talk + '\n\n\n\n'
      encode_str = end_text.encode('utf-8')
      
      # Finish and move on to the next
      adder += 1
      print '\rNumber of TED Talks scrapped: ' + str(adder)
      
      # Save the collected talk with the rest
      with open('../data/scrapped_ted_talks.txt', 'a') as ted_file:
        ted_file.write(encode_str)
      
  # In case of error, print the error encountered
  except urllib2.HTTPError, err:
    print err.code

################################################################################

################################################################################
# Scan all links
while len(queue_links) > 0:
  # Check a new URL
  url = queue_links.popleft()
  fetched = urllib2.urlopen(url)
  content = fetched.read()
  body = html.fromstring(content)
  links = body.xpath('//a/@href')
  
  # Try to scrap all links found
  for link in links:
    if link not in proc_links:
      proc_links.add(link)
      
      # Download transcript content if it is a Talk
      if ('/talks/' in link):
        link = link.replace('.html', '')
        link = link.replace('/lang/eng/', '/')
        link = link + '/transcript?language=en'
        link = 'http://www.ted.com' + link
        scrap_talk(link)
      if ('/talks?' in link):
        link = 'http://www.ted.com' + link
        queue_links.append(link)

print 'Done!\n'
################################################################################
# END OF SCRIPT
################################################################################
