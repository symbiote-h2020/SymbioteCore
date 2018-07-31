FROM ubuntu

WORKDIR /home

COPY ./apacheSetup.sh apacheSetup.sh
COPY ./configuration configuration
COPY ./config.txt config.txt

RUN chmod +x apacheSetup.sh && bash apacheSetup.sh

EXPOSE 80 443

CMD service apache2 start && tail -f /dev/null
