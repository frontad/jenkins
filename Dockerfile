FROM centos
RUN yum install -y epel-release && \
    yum clean all && \
    yum install -y supervisor \
    java-1.8.0-openjdk-devel \
    openssh-server \
    python36 python36-setuptools && \
    yum clean all && rm -rf /var/cache/yum 
RUN easy_install-3.6 pip
RUN curl -fsSL https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-18.06.0.ce-3.el7.x86_64.rpm \
    -o /tmp//docker.rpm && \
    yum install /tmp/docker.rpm -y && \
    rm -f /tmp/docker.rpm   
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT ${agent_port}

RUN groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

VOLUME /var/jenkins_home
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

ENV TINI_VERSION 0.14.0
ENV TINI_SHA 6c41ec7d33e857d4779f14d9c74924cab0c7973485d2972419a3b7c7620ff5fd

RUN curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static-amd64 -o /bin/tini && chmod +x /bin/tini \
  && echo "$TINI_SHA  /bin/tini" | sha256sum -c -

COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.121.2}

#ARG JENKINS_SHA=2d71b8f87c8417f9303a73d52901a59678ee6c0eefcf7325efed6035ff39372a
ARG JENKINS_SHA=da0f9d106e936246841a898471783fb4fbdbbacc8d42a156b7306a0855189602

ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
  && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref

EXPOSE ${http_port}
EXPOSE ${agent_port}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER ${user}

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
#ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

COPY plugins.sh /usr/local/bin/plugins.sh
COPY install-plugins.sh /usr/local/bin/install-plugins.sh

USER root
RUN echo 'root:8lab.8lab' | chpasswd
COPY supervisord.conf /etc/supervisord.conf
COPY supervisor /opt/supervisor
COPY entrypoint.sh /opt/script/entrypoint.sh
RUN chmod +x /opt/script/entrypoint.sh
#RUN chown -R jenkins:jenkins /var/jenkins_home
RUN mkdir -p /var/log/supervisor
RUN ln -sf /dev/stdout /var/log/supervisor/sshd_stdout.log
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
#ENTRYPOINT ["/bin/tini", "--", "/usr/bin/supervisord"]
WORKDIR /opt/script
ENTRYPOINT ["/opt/script/entrypoint.sh"]
