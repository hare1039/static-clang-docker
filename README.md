# static-clang-docker
This docker image (`hare1039/static-cpp:latest`) contains LLVM, clang, libcxx, libcxxabi, libunwind, musl c, and boost.

Currently `hare1039/static-cpp:latest` contains 
- llvm 7.0.0
- boost git master (boost asio 1.68.0 cannot compile by clang 7.0.0 , but fix by [this PR](https://github.com/boostorg/asio/pull/91), so I switch to git master)
- musl 1.1.12

If you need customlize versions, you can build the image by cloning this repo and send `--build-arg`.

support build arg
- `LLVM_VER` = `7.0.0`
- `BOOST_GIT_CLONE_CMD` = `git clone --recursive https://github.com/boostorg/boost.git boost; # must clone into folder ./boost`

Or use `Dockerfile.alternative`

support build arg
- `LLVM_VER`  = `7.0.0`
- `BOOST_VER` = `1.68.0`

The building process will take a long time. It took 4 hours for my laptop to build the image. 

BTW, building process will also take ~11G space in disk. Please make sure you have enough space.

Final image is ~2G in size.

Output binary will contain libcxx, libcxxabi, libunwind, musl c, optional boost libraries.

All staticly linked.

# static-clang-docker
How to use

First run the image and start bash in the container. You can run `/clang++.sh`, which is a wrapper script predefine all llvm paths, to compile your code.
