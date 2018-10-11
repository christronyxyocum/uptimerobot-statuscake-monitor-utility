#!/usr/bin/env bash
#
wget https://github.com/SimonKagstrom/kcov/archive/master.tar.gz &&
tar xzf master.tar.gz &&
cd kcov-master &&
mkdir build &&
cd build &&
cmake .. &&
make &&
sudo make install &&
cd ../.. &&
rm -rf kcov-master &&
mkdir -p coverage &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -h' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -h &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --help' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --help &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -l' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -l &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --list' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --list &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -n' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -n &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --no-prompt' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --no-prompt &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -w' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -w &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --webhook' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --webhook &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -c http' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -c http &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --create http' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --create http &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -c ping' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -c ping &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --create ping' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --create ping &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -c port' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -c port &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --create port' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --create port &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -c keyword' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -c keyword &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --create keyword' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --create keyword &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -f' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -f &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --find' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --find &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -a' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -a &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --alerts' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --alerts &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -s' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -s &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --stats' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --stats &&
#echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -d all' &&
#kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -d all &&
#echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --delete all' &&
#kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --delete all &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -i travisone' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -i travisone &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --info travistwo' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --info travistwo &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -p all' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -p all &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --pause all' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --pause all &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -u all' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -u all &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --unpause all' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --unpause all &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh -r all' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh -r all &&
echo 'Running kcov for travis_uptimerobot_monitor_utility.sh --reset all' &&
kcov coverage Travis/travis_uptimerobot_monitor_utility.sh --reset all &&
bash <(curl -s https://codecov.io/bash)