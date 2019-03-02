#!/bin/bash

set -e

if [ ! -x "/usr/local/go/bin/go" ]; then
	echo Installing Go: $GO_VERSION
	wget --no-verbose -O /go.tar.gz https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
	tar -C /usr/local -xzf /go.tar.gz
fi

PATH="/usr/local/go/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"

echo Target version: $BEATS_VERSION

BRANCH=$(echo $BEATS_VERSION | awk -F \. {'print $1 "." $2'})
echo Target branch: $BRANCH

if [ ! -d "$GOPATH/src/github.com/elastic/beats" ]; then go get -v github.com/elastic/beats; fi

cd $GOPATH/src/github.com/elastic/beats
git checkout $BRANCH

IFS=","
BEATS_ARRAY=($BEATS)

for BEAT in "${BEATS_ARRAY[@]}"
do
    # build
    cd $GOPATH/src/github.com/elastic/beats/$BEAT
    if [ "$BEAT" = "packetbeat" ]; then
	CGO_ENABLED=1 CC=arm-linux-gnueabi-gcc CGO_LDFLAGS="-L/usr/lib/arm-linux-gnueabihf" make
    else
	make
    fi
    cp $BEAT /build

    # package
    DOWNLOAD=$BEAT-$BEATS_VERSION-linux-x86.tar.gz
    if [ ! -e $DOWNLOAD ]; then wget --no-verbose https://artifacts.elastic.co/downloads/beats/$BEAT/$DOWNLOAD; fi
    tar xf $DOWNLOAD

    cp $BEAT $BEAT-$BEATS_VERSION-linux-x86
    tar zcf $BEAT-$BEATS_VERSION-linux-arm$GOARM.tar.gz $BEAT-$BEATS_VERSION-linux-x86
    cp $BEAT-$BEATS_VERSION-linux-arm$GOARM.tar.gz /build
done
