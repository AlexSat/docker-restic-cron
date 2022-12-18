ARG HAS_BEFORE_AFTER_SCRIPTS=no
FROM alpine:3.12 as base

ARG TARGETARCH=amd64
ARG BEFORE_AFTER_SCRIPTS_PATH

RUN apk add --no-cache curl=~7 bash=~5

ARG RCLONE_VERSION=v1.55.1

COPY ./scripts/install_rclone.sh /scripts/
RUN /scripts/install_rclone.sh "$RCLONE_VERSION" "$TARGETARCH"

ARG RESTIC_VERSION=0.12.0

COPY ./scripts/install_restic.sh /scripts/
RUN /scripts/install_restic.sh "$RESTIC_VERSION" "$TARGETARCH"

# Set some default environment variables
ENV BACKUP_DEST="/backups"
ENV BACKUP_NAME="backup"
ENV PATH_TO_BACKUP="/data"
ENV CRON_SCHEDULE=""
ENV VERIFY_CRON_SCHEDULE=""

COPY ./scripts /scripts

from base as before_after_scripts_yes
ONBUILD COPY ${BEFORE_AFTER_SCRIPTS_PATH} /scripts/

from base as before_after_scripts_no
ONBUILD RUN echo "No before/after script folder was passed. So skip it."

FROM before_after_scripts_${HAS_BEFORE_AFTER_SCRIPTS} as final

HEALTHCHECK CMD /scripts/healthcheck.sh

VOLUME /root/.config

CMD [ "/scripts/start.sh" ]
