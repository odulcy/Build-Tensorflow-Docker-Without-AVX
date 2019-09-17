# Ubuntu 19.04 (disco) 
# Need to compile Tensorflow
# from source to disable avx flag
ARG BASE_CONTAINER=ubuntu:disco
FROM $BASE_CONTAINER

ARG TENSORFLOW_VERSION=r1.14

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    python-dev \
    python-pip \
    python-setuptools \
    git \
    pkg-config \
    zip \
    g++ \
    zlib1g-dev \
    unzip \
    python3 \
    wget \
 && rm -rf /var/lib/apt/lists/*

RUN pip install -U six numpy wheel mock 'future>=0.17.1'
RUN pip install -U keras_applications==1.0.6 --no-deps
RUN pip install -U keras_preprocessing==1.0.5 --no-deps

RUN wget \
    https://github.com/bazelbuild/bazel/releases/download/0.26.1/bazel-0.26.1-installer-linux-x86_64.sh \
 && chmod +x bazel-0.26.1-installer-linux-x86_64.sh \
 && ./bazel-0.26.1-installer-linux-x86_64.sh

RUN git clone https://github.com/tensorflow/tensorflow.git && \
    cd tensorflow && \
    git checkout $TENSORFLOW_VERSION

RUN echo 'build --action_env PYTHON_BIN_PATH="/usr/bin/python" \n\
build --action_env PYTHON_LIB_PATH="/usr/local/lib/python2.7/dist-packages" \n\
build --python_path="/usr/bin/python"\n\
build:xla --define with_xla_support=true\n\
build --config=xla\n\
build --action_env TF_NEED_OPENCL_SYCL="0"\n\
build --action_env TF_NEED_ROCM="0"\n\
build --action_env TF_NEED_CUDA="0"\n\
build --action_env TF_DOWNLOAD_CLANG="0"\n\
build:opt --copt=-march=native\n\
build:opt --copt=-Wno-sign-compare\n\
build:opt --host_copt=-march=native\n\
build:opt --define with_default_optimizations=true\n\
build:v2 --define=tf_api_version=2\n\
test --flaky_test_attempts=3\n\
test --test_size_filters=small,medium\n\
test --test_tag_filters=-benchmark-test,-no_oss,-oss_serial\n\
test --build_tag_filters=-benchmark-test,-no_oss\n\
test --test_tag_filters=-gpu\n\
test --build_tag_filters=-gpu\n\
build --action_env TF_CONFIGURE_IOS="0"'> /tensorflow/.tf_configure.bazelrc

# Volume configuration
VOLUME ["/tmp/tensorflow_pkg"]

WORKDIR /tensorflow

RUN echo '#!/bin/bash\n\
bazel build --config=opt //tensorflow/tools/pip_package:build_pip_package\n\
./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg'> /tensorflow/launch_bazel.sh

RUN chmod u+x /tensorflow/launch_bazel.sh

CMD ["//tensorflow/launch_bazel.sh"]

