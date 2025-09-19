FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    fortune-mod \
    cowsay \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Add cowsay to PATH
ENV PATH="/usr/games:${PATH}"

# Create app directory
WORKDIR /app

# Copy the wisecow script
COPY wisecow.sh .

# Make the script executable
RUN chmod +x wisecow.sh

# Expose port 4499
EXPOSE 4499

# Run the wisecow script
CMD ["./wisecow.sh"]