FROM 357210185381.dkr.ecr.us-east-1.amazonaws.com/wormbase/website-env:1.0.2

COPY . /usr/local/wormbase/website/

RUN chmod u+x /usr/local/wormbase/website

WORKDIR /usr/local/wormbase/website

# Define default command.
ENTRYPOINT ["dumb-init", "--"]
CMD ["./script/wormbase-daemon-for-docker.sh"]
