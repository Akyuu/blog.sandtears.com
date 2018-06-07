#!/bin/bash
/Users/sandtears/.rvm/gems/ruby-2.5.1@daily/bin/jekyll b
/usr/bin/rsync -av --delete ~/blog/ ~/dropbox/VPS_Sync/blog/blog.sandtears.com/
