#!/usr/bin/env bash


apt-get install curl g++ gcc autoconf automake bison libc6-dev \
                     libffi-dev libgdbm-dev libncurses5-dev libsqlite3-dev libtool \
                     libyaml-dev make patch pkg-config sqlite3 zlib1g-dev libgmp-dev \
                     libreadline-dev libssl-dev gpg sudo

gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable

usermod -a -G rvm root

id

groups

newgrp rvm

groups

source /etc/profile.d/rvm.sh

echo "==================== Installing Ruby ======================="
rvm install ruby-3.1.0

echo "==================== Selecting Ruby ======================="
rvm --default use ruby-3.1.0

echo "==================== Installing Cocoa Pods ======================="
gem install cocoapods

# seems thet cocoapods really wants rsync
echo "==================== Install Rsync ======================="
apt-get install -y rsync
which rsync

echo "==================== Running Cocoa Pods Setup ======================="
export COCOAPODS_ALLOW_ROOT=1
pod setup --allow-root
which pod



