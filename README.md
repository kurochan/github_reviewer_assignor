github_reviewer_assign_bot
========

inspired by [git で reviewer を探すスクリプトを作りました / LINE Engineers' Blog](http://developers.linecorp.com/blog/ja/?p=3832)

# How to run
ruby 2.3 on Ubuntu16.04 

```
$ sudo apt -y install ruby git-core
$ sudo gem install octokit
$ git clone https://github.com/kurochan/github_reviewer_assign_bot
$ cp github_reviewer_assign_bot/config.rb{.example,}
# edit config file
$ vim github_reviewer_assign_bot/config.rb

$ ruby github_reviewer_assign_bot/main.rb
```
