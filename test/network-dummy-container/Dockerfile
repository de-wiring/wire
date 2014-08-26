FROM ubuntu:latest
MAINTAINER de_wiring

# get us some ruby
RUN apt-get update -yqq
RUN apt-get install -yqq ruby

# add network dummy script and make it an entrypoint
ADD ./lib/nwd.rb /opt/nwd
ENTRYPOINT ["/opt/nwd."]
