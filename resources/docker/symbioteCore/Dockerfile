FROM openjdk:8-jdk-alpine

#Enter desired gradle version
ENV GRADLE_VERSION=3.3
ENV HOME=/home

WORKDIR /home

#Download dependencies
RUN apk --no-cache add \
	screen \
	git \
	unzip \
	wget \
	bash \
	curl \
	libstdc++ \
	util-linux \
	openssl \
	busybox-extras \
	vim 

#Download and setup gradle
RUN curl -O --location --silent --show-error https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    	&& mkdir /opt \
    	&& unzip -q gradle-${GRADLE_VERSION}-bin.zip -d /opt \
    	&& ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle \
    	&& rm -f gradle-${GRADLE_VERSION}-bin.zip
ENV PATH $PATH:/opt/gradle/bin

#Copy symbioteCore.sh script
COPY ./symbioteCore.sh symbioteCore.sh
COPY ./configuration configuration
COPY ./config.txt config.txt
RUN chmod +x symbioteCore.sh

#Download symbioteCore components
RUN bash ./symbioteCore.sh clone_setup_and_build

EXPOSE 8100 8101 8250 8443 8777

CMD bash ./symbioteCore.sh start
