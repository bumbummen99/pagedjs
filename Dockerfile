FROM mcr.microsoft.com/playwright:v1.32.3-focal

# Install Node.js explicitly
RUN apt-get update && \
    apt-get install -y nodejs npm && \
    rm -rf /var/lib/apt/lists/*

# Application parameters and variables
ENV NODE_ENV=development
ENV PORT=9090
ENV DIRECTORY /home/pwuser/pagedjs

# Configuration for Chrome
ENV CONNECTION_TIMEOUT=60000

# Configuration for GS4JS
RUN echo "GS4JS_HOME=/usr/lib/$(gcc -dumpmachine)"

# Install ghostscript
RUN apt-get update && \
    apt-get install -y build-essential make gcc g++ && \
    apt-get -y install ghostscript && \
    apt-get clean && \
    apt-get install -y libgs-dev && \
    rm -rf /var/lib/apt/lists/*


# Update Freetype
COPY docker-font.conf /etc/fonts/local.conf
ENV FREETYPE_PROPERTIES="truetype:interpreter-version=35"
RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
RUN apt-get update \
    && apt-get install -y --no-install-recommends fontconfig ttf-mscorefonts-installer


# Install fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
RUN apt-get update && apt-get install -y wget --no-install-recommends \
    && apt-get install -y fonts-liberation fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
        --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge --auto-remove -y curl \
    && rm -rf /src/*.deb

# helps prevent zombie chrome processes.
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

RUN apt-get update && \
    apt-get install -y vim && \
    rm -rf /var/lib/apt/lists/*

# Install node-gyp globally (Node.js should already be installed)
RUN npm install -g node-gyp

RUN mkdir -p $DIRECTORY

# Set proper permissions instead of 777
RUN chmod -R 755 $DIRECTORY

WORKDIR $DIRECTORY

COPY package.json package-lock.json $DIRECTORY/
RUN npm install
RUN GS4JS_HOME="/usr/lib/$(gcc -dumpmachine)" npm install ghostscript4js

COPY . $DIRECTORY

EXPOSE $PORT

ENTRYPOINT ["dumb-init", "--"]
CMD ["npm", "start"]
