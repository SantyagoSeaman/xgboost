#!/bin/bash

if [ ${TASK} == "lint" ]; then
    make lint || exit -1
    echo "Check documentations..."
    make doxygen 2>log.txt
    (cat log.txt| grep -v ENABLE_PREPROCESSING |grep -v "unsupported tag") > logclean.txt
    echo "---------Error Log----------"
    cat logclean.txt
    echo "----------------------------"
    (cat logclean.txt|grep warning) && exit -1
    (cat logclean.txt|grep error) && exit -1
    exit 0
fi

cp make/travis.mk config.mk
make -f dmlc-core/scripts/packages.mk lz4


if [ ${TRAVIS_OS_NAME} == "osx" ]; then
    echo "USE_OPENMP=0" >> config.mk
fi

if [ ${TASK} == "python_test" ]; then
    make all || exit -1
    echo "-------------------------------"
    source activate python3
    python --version
    conda install numpy scipy pandas matplotlib nose scikit-learn
    python -m pip install graphviz
    python -m nose tests/python || exit -1
    source activate python2
    echo "-------------------------------"
    python --version
    conda install numpy scipy pandas matplotlib nose scikit-learn
    python -m pip install graphviz
    python -m nose tests/python || exit -1
    exit 0
fi

if [ ${TASK} == "python_lightweight_test" ]; then
    make all || exit -1
    echo "-------------------------------"
    source activate python3
    python --version
    conda install numpy scipy nose
    python -m pip install graphviz
    python -m nose tests/python/test_basic*.py || exit -1
    source activate python2
    echo "-------------------------------"
    python --version
    conda install numpy scipy nose
    python -m pip install graphviz
    python -m nose tests/python/test_basic*.py || exit -1
    exit 0
fi

if [ ${TASK} == "r_test" ]; then
    set -e
    export _R_CHECK_TIMINGS_=0
    export R_BUILD_ARGS="--no-build-vignettes --no-manual"
    export R_CHECK_ARGS="--no-vignettes --no-manual"

    curl -OL http://raw.github.com/craigcitro/r-travis/master/scripts/travis-tool.sh
    chmod 755 ./travis-tool.sh
    ./travis-tool.sh bootstrap
    make Rpack
    cd ./xgboost
    ../travis-tool.sh install_deps
    ../travis-tool.sh run_tests
    exit 0
fi

if [ ${TASK} == "java_test" ]; then
    set -e
    make jvm-packages
    cd jvm-packages
    ./create_jni.sh
    mvn clean install -DskipTests=true
    mvn test
fi
