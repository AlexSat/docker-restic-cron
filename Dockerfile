ARG HAS_BEFORE_AFTER_SCRIPTS=no
FROM alpine:3.20 as base

ARG TARGETARCH=amd64
ARG BEFORE_AFTER_SCRIPTS_PATH

RUN apk add --no-cache curl bash docker-cli mysql mysql-client pv jq postgresql-client

ARG RCLONE_VERSION=v1.69.0

COPY ./scripts/install_rclone.sh /scripts/
RUN /scripts/install_rclone.sh "$RCLONE_VERSION" "$TARGETARCH"

ARG RESTIC_VERSION=0.18.1

COPY ./scripts/install_restic.sh /scripts/
RUN /scripts/install_restic.sh "$RESTIC_VERSION" "$TARGETARCH"

# Set some default environment variables
ENV BACKUP_DEST="/backups"
ENV BACKUP_NAME="backup"
ENV PATH_TO_BACKUP="/data"
ENV CRON_SCHEDULE=""
ENV VERIFY_CRON_SCHEDULE=""

COPY ./scripts /scripts

HEALTHCHECK CMD /scripts/healthcheck.sh

VOLUME /root/.config
VOLUME /scripts/backup
VOLUME /scripts/restore

CMD [ "/scripts/start.sh" ]
