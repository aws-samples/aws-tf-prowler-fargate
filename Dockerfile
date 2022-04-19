# Pull Amazon Linux image
FROM public.ecr.aws/amazonlinux/amazonlinux:latest

LABEL maintainer="https://github.com/prowler-cloud/prowler"

HEALTHCHECK NONE

# Define Prowler user credentials
ARG USERNAME=prowler
ARG USERID=34000

# Copy Prowler script to path
COPY run-prowler-reports.sh /root

# Install dependencies
RUN yum install -y shadow-utils && \
  useradd -s /bin/sh -U -u ${USERID} ${USERNAME} && \
  yum install -y python3 bash curl jq coreutils py3-pip which unzip && \
  yum install git \
  yum upgrade -y && \
  yum clean all && \
  pip3 install --upgrade pip && \
  pip3 install boto3 detect-secrets==1.0.3 && \
  pip3 cache purge && \
  curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip && \
  unzip awscliv2.zip && \
  aws/install && \
  rm -rf aws awscliv2.zip /var/cache/yum && \
  rm /usr/bin/python && \
  ln -s /usr/bin/python3 /usr/bin/python

# Clone Prowler repo and add to path
RUN git clone https://github.com/prowler-cloud/prowler && \
    mv root/run-prowler-reports.sh /prowler && \
    chown -R prowler:prowler /prowler

# Run Prowler scan in AWS Organization using the Prowler user
WORKDIR /prowler

USER prowler
CMD  bash run-prowler-reports.sh
