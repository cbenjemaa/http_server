ARG IMG_TAG=3.1.1-alpine
# Use a fixed alpine docker image
FROM ruby:$IMG_TAG

# install sudo as root
RUN apk add --update sudo

ARG USER=app-user
ARG PORT=8080

# Create a non-root user to run the http_server
RUN adduser -D $USER -u 1337 -h /app\
        && mkdir -p /etc/sudoers.d \
        && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
        && chmod 0440 /etc/sudoers.d/$USER

# Set the user for RUN, CMD or ENTRYPOINT calls from now on
USER $USER

# Set the base directory that will be used from now on
WORKDIR /app

COPY http_server.rb .

# This gives a signal that our web server is about to start
# It helps with debugging
RUN echo "Starting a Ruby http_server"

EXPOSE $PORT

CMD ruby http_server.rb
