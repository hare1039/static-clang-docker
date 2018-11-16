#!/bin/bash
# include order: c++ header -> musl c header
# link order: crt1.o -> crtbegin.o ->
#             -L -> user.o -> libc++ -> libpthread -> libc++abi -> libunwind -> libc -> crtend.o
COMPILE_LIB="FALSE"
for option in "$@"; do
    if [[ "$option" == "-c" ]]; then
        COMPILE_LIB="TRUE";
        break;
    fi
done

if [[ "$COMPILE_LIB" == "TRUE" ]]; then
    clang++ "$@" \
        -static \
        -nostdinc \
        -isystem /usr/local/include/c++/v1 \
        -isystem /usr/local/lib/clang/*/include \
        -isystem /musl-cross-make/musl-*/include \
        -isystem /usr/local/x86_64-linux-musl/include \
        -I /usr/local/include

else
    clang++ "$@" \
        -static \
        -nostdinc \
        -isystem /usr/local/include/c++/v1 \
        -isystem /usr/local/lib/clang/*/include \
        -isystem /musl-cross-make/musl-*/include \
        -isystem /usr/local/x86_64-linux-musl/include \
        -I /usr/local/include \
        -L /usr/local/x86_64-linux-musl/lib \
        -L /usr/local/lib \
        -nostartfiles /usr/local/x86_64-linux-musl/lib/crt1.o \
        /usr/local/lib/gcc/x86_64-linux-musl/*/crtbegin.o \
        /usr/local/lib/gcc/x86_64-linux-musl/*/crtend.o \
        -Wl,-dynamic-linker,/usr/local/x86_64-linux-musl/lib/ld-musl-x86_64.so.1 \
        -Wl,-rpath,/usr/local/x86_64-linux-musl/lib,-rpath,/usr/local/lib \
        -nodefaultlibs -stdlib=libc++ -lc++ -lpthread -lc++abi -lunwind -lm -lc
fi
