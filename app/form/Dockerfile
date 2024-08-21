FROM amazonlinux:latest

COPY ./form .

RUN yum update -y && \
    yum install -y shadow-utils curl --allowerasing && \
    useradd -m form

RUN chmod 777 ./form

USER form

EXPOSE 8080

CMD ["./forms"]