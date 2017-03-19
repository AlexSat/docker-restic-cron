FROM ubuntu:xenial
MAINTAINER ViViDboarder <vividboarder@gmail.com>

RUN apt-get update \
        && apt-get install -y software-properties-common python-software-properties \
        && add-apt-repository ppa:duplicity-team/ppa \
        && apt-get update \
        && apt-get install -y duplicity python-setuptools \
        python-boto python-swiftclient python-pexpect openssh-client \
        && rm -rf /var/apt/lists/*

VOLUME "/root/.cache/duplicity"
VOLUME "/backups"

ENV BACKUP_DEST="file:///backups"
ENV BACKUP_NAME="backup"
ENV PATH_TO_BACKUP="/data"
ENV PASSPHRASE="Correct.Horse.Battery.Staple"

# Cron schedules
ENV CRON_SCHEDULE=""
ENV VERIFY_CRON_SCHEDULE=""

ADD entrypoint.sh /
ADD backup.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
