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
    echo 'Running kcov for no monitors within account' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -l &&
    echo 'Creating Travis test monitors' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/ur_prep.sh &&
    echo 'Sleeping to allow tests to be checked' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/sleep.sh &&
    echo 'Running kcov for travis_tronitor.sh' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh &&
    echo 'Running kcov for travis_tronitor.sh -h' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -h &&
    echo 'Running kcov for travis_tronitor.sh --help' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --help &&
    echo 'Running kcov for no argument for option that requires one' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -c &&
    echo 'Running kcov for non-existent option' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -x &&
    echo 'Running kcov for travis_tronitor.sh -n' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -n &&
    echo 'Running kcov for travis_tronitor.sh --no-prompt' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --no-prompt &&
    echo 'Running kcov for travis_tronitor.sh -c http' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -c http &&
    echo 'Running kcov for travis_tronitor.sh --create ping' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --create ping &&
    echo 'Running kcov for travis_tronitor.sh -c port' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -c port &&
    echo 'Running kcov for travis_tronitor.sh --create keyword' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --create keyword &&
    echo 'Testing create with bad monitor type' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -c foobar &&
    echo 'Running kcov for travis_tronitor.sh -a' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -a &&
    echo 'Running kcov for travis_tronitor.sh --alerts' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --alerts &&
    echo 'Running kcov for travis_tronitor.sh -s' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -s &&
    echo 'Running kcov for travis_tronitor.sh --stats' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --stats &&
    echo 'Running kcov for travis_tronitor.sh -i travisone' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -i travisone &&
    echo 'Running kcov for travis_tronitor.sh --info travistwo' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --info travistwo &&
    echo 'Running kcov for info option with invalid monitor friendly name' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -i foobar &&
    echo 'Running kcov for info option with invalid monitor ID' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -i 123456789 &&
    echo 'Running kcov for info option with valid monitor ID' &&
    travisThreeId=$(
        curl -s -X POST getMonitors -d "api_key=${travisApiKey}" -d "format=json" > foo
        grep TravisThree foo | grep -Po '"id":[!0-9]*' foo | awk -F: '{print $2}'
    )
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -i "${travisThreeId}" &&
    echo 'Running kcov for travis_tronitor.sh -n' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -n &&
    echo 'Running kcov for travis_tronitor.sh -p all' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -p all &&
    echo 'Running kcov for travis_tronitor.sh -w' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -w &&
    echo 'Running kcov for travis_tronitor.sh --webhook' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --webhook &&
    echo 'Running kcov for travis_tronitor.sh --pause GoogleKeyword' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --pause GoogleKeyword &&
    echo 'Running kcov for travis_tronitor.sh --find' &&
    sudo expect ./Travis/Scripts/Expects/kcov_find_expect_long.exp
    echo 'Running kcov for travis_tronitor.sh -n' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -n &&
    echo 'Running kcov for travis_tronitor.sh -r TravisOne' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -r TravisOne &&
    echo 'Running kcov for travis_tronitor.sh --reset TravisTwo' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --reset TravisTwo &&
    echo 'Running kcov for travis_tronitor.sh -u GooglePing' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -u GooglePing &&
    echo 'Running kcov for travis_tronitor.sh --unpause all' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --unpause all &&
    echo 'Running kcov for travis_tronitor.sh --list' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --list &&
    echo 'Running kcov for travis_tronitor.sh -d TravisOne' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh -d TravisOne &&
    echo 'Running kcov for travis_tronitor.sh --delete TravisTwo' &&
    kcov --exclude-line=72,103,104 coverage Travis/Scripts/travis_tronitor.sh --delete TravisTwo &&
    bash <(curl -s https://codecov.io/bash -s coverage/kcov-merged)
