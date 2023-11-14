FROM rockylinux/rockylinux:9 as download_ssp

ARG SIMPLE_SAML_PHP_VERSION=2.1.0
ARG SIMPLE_SAML_PHP_HASH=0ad2d7bd51856b8cd57019001e72a6fc1004b3446222486bec84c4db328dd313

RUN dnf install -y wget \
    && ssp_version=$SIMPLE_SAML_PHP_VERSION; \
           ssp_hash=$SIMPLE_SAML_PHP_HASH; \
           wget https://github.com/simplesamlphp/simplesamlphp/releases/download/v$ssp_version/simplesamlphp-$ssp_version.tar.gz \
    && echo "$ssp_hash  simplesamlphp-$ssp_version.tar.gz" | sha256sum -c - \
    && cd /var \
    && tar xzf /simplesamlphp-$ssp_version.tar.gz \
    && mv simplesamlphp-$ssp_version simplesamlphp

FROM rockylinux/rockylinux:9

LABEL maintainer="Unicon, Inc."

ARG PHP_VERSION=8.1

COPY --from=download_ssp /var/simplesamlphp /var/simplesamlphp

RUN dnf module enable -y php:$PHP_VERSION \
    && dnf install -y httpd php \
    && dnf clean all \
    && rm -rf /var/cache/yum

RUN echo $'\nSetEnv SIMPLESAMLPHP_CONFIG_DIR /var/simplesamlphp/config\nAlias /simplesaml /var/simplesamlphp/public\n \
<Directory /var/simplesamlphp/public>\n \
    Require all granted\n \
</Directory>\n' \
       >> /etc/httpd/conf/httpd.conf

COPY httpd-foreground /usr/local/bin/

EXPOSE 80 443

CMD ["httpd-foreground"]
