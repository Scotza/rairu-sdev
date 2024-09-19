FROM debian

# Define arguments for NGROK token and region
ARG NGROK_TOKEN
ARG REGION=ap

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget unzip vim curl python3

# Download and install ngrok
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O /ngrok-v3-stable-linux-amd64.tgz \
    && tar -xzf /ngrok-v3-stable-linux-amd64.tgz -C / \
    && chmod +x /ngrok

# Set up SSH and ngrok configuration
RUN mkdir /run/sshd \
    && echo "/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 &" >> /openssh.sh \
    && echo "sleep 5" >> /openssh.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"ssh info:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\\nROOT Password: craxid\\\")\" || echo \"\nError: Invalid NGROK_TOKEN provided.\"" >> /openssh.sh \
    && echo '/usr/sbin/sshd -D' >> /openssh.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo root:craxid | chpasswd \
    && chmod 755 /openssh.sh

# Expose necessary ports
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000

# Command to run on container start
CMD /openssh.sh

# Additional ngrok installation
RUN curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
    | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
    | tee /etc/apt/sources.list.d/ngrok.list \
    && apt update \
    && apt install ngrok
