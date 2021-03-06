ARG LLVM_VER=700
ARG BOOST_GIT_CLONE_CMD="git clone --recursive https://github.com/boostorg/boost.git boost"

FROM ubuntu:18.04 AS builder
MAINTAINER hare1039 hare1039@hare1039.nctu.me

ARG LLVM_VER
ARG BOOST_GIT_CLONE_CMD

RUN apt-get update && \
    apt-get install -y --no-install-recommends make            \
                                               git             \
                                               wget            \
                                               ca-certificates \
                                               xz-utils        \
                                               patch           \
                                               subversion      \
                                               ninja-build     \
                                               python          \
                                               cmake           \
                                               zlib1g-dev      \
                                               bzip2           \
                                               g++          && \
    git clone https://github.com/richfelker/musl-cross-make.git /musl-cross-make && \
    cd /musl-cross-make/                                                         && \
    touch config.mak                                                             && \
    echo "TARGET = x86_64-linux-musl" >> config.mak                              && \
    echo "OUTPUT = /usr/local"        >> config.mak                              && \
    make install

RUN mkdir /root/workspace                                                                         && \
    cd /root/workspace                                                                            && \
    svn co http://llvm.org/svn/llvm-project/llvm/tags/RELEASE_${LLVM_VER}/final/ llvm             && \
    cd llvm/tools                                                                                 && \
    svn co http://llvm.org/svn/llvm-project/cfe/tags/RELEASE_${LLVM_VER}/final/ clang             && \
    cd ../..                                                                                      && \
    svn co http://llvm.org/svn/llvm-project/libcxx/tags/RELEASE_${LLVM_VER}/final/ libcxx         && \
    svn co http://llvm.org/svn/llvm-project/libcxxabi/tags/RELEASE_${LLVM_VER}/final/ libcxxabi   && \
    svn co http://llvm.org/svn/llvm-project/libunwind/trunk libunwind

RUN cd /root/workspace/libunwind && mkdir build && cd build    && \
    cmake -G "Ninja" -DCMAKE_C_COMPILER='x86_64-linux-musl-gcc'   \
                     -DCMAKE_CXX_COMPILER='x86_64-linux-musl-g++' \
                     -DCMAKE_BUILD_TYPE=Release                   \
                     -DLLVM_PATH=/root/workspace/llvm             \
                     -DLIBUNWIND_ENABLE_SHARED=OFF ..          && \
    ninja

RUN cd /root/workspace/libcxxabi && mkdir build && cd build        && \
    cmake -G "Ninja" -DCMAKE_C_COMPILER='x86_64-linux-musl-gcc'       \
                     -DCMAKE_CXX_COMPILER='x86_64-linux-musl-g++'     \
                     -DCMAKE_BUILD_TYPE=Release                       \
                     -DLLVM_PATH=/root/workspace/llvm                 \
                     -DCMAKE_SHARED_LINKER_FLAGS="-L/root/workspace/libunwind/build/lib" \
                     -DLIBCXXABI_USE_LLVM_UNWINDER=ON                                    \
                     -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON                               \
                     -DLIBCXXABI_LIBUNWIND_PATH="/root/workspace/libunwind"              \
                     -DLIBCXXABI_ENABLE_SHARED=OFF                                       \
                     -DLIBCXXABI_ENABLE_STATIC=ON                                        \
                     -DLIBCXXABI_LIBCXX_INCLUDES="/root/workspace/libcxx/include" ..  && \
    ninja

RUN cd /root/workspace/libcxx && mkdir build && cd build       && \
    cmake -G "Ninja" -DCMAKE_C_COMPILER='x86_64-linux-musl-gcc'   \
                     -DCMAKE_CXX_COMPILER='x86_64-linux-musl-g++' \
                     -DCMAKE_BUILD_TYPE=Release                   \
                     -DLLVM_PATH=/root/workspace/llvm             \
                     -DLIBCXX_HAS_MUSL_LIBC=ON                    \
                     -DLIBCXX_HAS_GCC_S_LIB=OFF                   \
                     -DLIBCXX_CXX_ABI=libcxxabi                   \
                     -DLIBCXX_ENABLE_SHARED=OFF                   \
                     -DLIBCXX_ENABLE_STATIC=ON                    \
                     -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON        \
                     -DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON        \
                     -DLIBCXXABI_USE_LLVM_UNWINDER=ON             \
                     -DLIBCXX_CXX_ABI_INCLUDE_PATHS="/root/workspace/libcxxabi/include"        \
                     -DLIBCXX_CXX_ABI_LIBRARY_PATH="/root/workspace/libcxxabi/build/lib" .. && \
    ninja

RUN mkdir /root/workspace/build                                     && \
    cd    /root/workspace/build                                     && \
    cmake -G "Ninja" -DCMAKE_INSTALL_PREFIX=/usr/local                 \
                     -DCMAKE_BUILD_TYPE=Release                        \
                     -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;X86;Mips"    \
                     -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-pc-linux-musl \
                     -DBUILD_SHARED_LIBS=OFF                           \
                     -DCMAKE_C_COMPILER='x86_64-linux-musl-gcc'        \
                     -DCMAKE_CXX_COMPILER='x86_64-linux-musl-g++'      \
                     -DCMAKE_C_FLAGS="-static"                         \
                     -DCMAKE_CXX_FLAGS="-static"                       \
                     -DLIBCLANG_BUILD_STATIC=ON                        \
                     -DLLVM_ENABLE_PIC=OFF                             \
                     /root/workspace/llvm                           && \
    ninja

RUN cd /root/workspace/build           && \
    ninja install                      && \
    cd /root/workspace/libunwind/build && \
    ninja install                      && \
    cd /root/workspace/libcxxabi/build && \
    ninja install                      && \
    cd /root/workspace/libcxx/build    && \
    ninja install                      && \
    ln -s /usr/local/x86_64-linux-musl/lib/libc.so /lib/ld64.so.1

RUN cd /root/workspace                                            && \
    ${BOOST_GIT_CLONE_CMD} ; cd boost

ENV PATH="/usr/local/x86_64-linux-musl/bin:$PATH"
COPY clang++.sh /clang++.sh
RUN chmod +x /clang++.sh

RUN cd /root/workspace/boost/tools/build                          && \
    ./bootstrap.sh                                                && \
    ./b2 install --prefix=/usr/local                              && \
    cd ../..                                                      && \
    echo "using clang : musl : /clang++.sh ; " >> tools/build/src/user-config.jam && \
    bjam --prefix=/usr/local --build-dir=/tmp/boost --without-python \
         variant=release runtime-link=static link=static toolset=clang-musl install

# From here, the clang/llvm toolchain, boost library, and musl c library are built and installed.
# Next is to copy all built folders to a new image layer, making the image smaller (10G -> 2G)

RUN rm -rf /root                             && \
    apt-get autoremove -y gcc                && \
    mkdir /musl                              && \
    mv /musl-cross-make/musl-*/include /musl && \
    rm -rf /musl-cross-make                  && \
    mkdir -p /musl-cross-make/musl-release   && \
    mv /musl/include /musl-cross-make/musl-release/include

FROM ubuntu:18.04
MAINTAINER hare1039 hare1039@hare1039.nctu.me

COPY --from=builder /usr/local /usr/local
COPY --from=builder /musl-cross-make /musl-cross-make
COPY clang++.sh /clang++.sh

RUN ln -s /usr/local/x86_64-linux-musl/lib/libc.so /lib/ld64.so.1 && \
    chmod +x /clang++.sh
ENV PATH="/usr/local/x86_64-linux-musl/bin:$PATH"
ENV CXX=/clang++.sh