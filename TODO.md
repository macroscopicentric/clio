# Stuff That Needs To Happen To Have an MVP

## Stuff to Get Back Basic Functionality

1. twitter archive ingest is working again, verify backup works (both the act of backing up and the act of saving anything to disk)

## Stuff That Would Be Nice to Automate

1. identifying when you need a twitter archive
2. going to fetch the twitter archive
3. set up some sort of cron/perma process?
4. make it an interactive cli for things like grabbing the twitter archive or (eventually) inputting handles

## Expected Basic MVP functionality

1. how am i currently doing auth tokens etc (did i really just hardcode in config.yml, incredible), how should i be doing that
2. add an actual database lol, instead of just saving to csv (open question: actually stick to postgres as originally proposed?)
3. add new platforms (Wordpress, Instagram, Mastodon, Tiktok?, Tumblr?)
4. actually build out the SocialMediaBackup class as a layer between the bin script and the Twitter class.