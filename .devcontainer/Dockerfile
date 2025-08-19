FROM python:3.10-slim-buster

WORKDIR /workspaces/ad_monitor

RUN apt-get update && apt-get install -y curl

COPY post-create.sh /usr/local/share/

RUN chmod +x /usr/local/share/post-create.sh

CMD ["/bin/bash"]
