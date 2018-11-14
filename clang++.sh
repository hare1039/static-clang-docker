# include order: c++ header -> musl c header
# link order: crt1.o -> crtbegin.o ->
#             -L -> user.o -> libc++ -> libpthread -> libc++abi -> libunwind -> libc -> crtend.o

clang++ "$@" \
        -static \
        -nostdinc \
        -isystem /usr/local/include/c++/v1 \
        -isystem /musl-cross-make/musl-1.1.20/include \
        -isystem /usr/local/x86_64-linux-musl/include \
        -I /usr/local/include \
        -L /usr/local/x86_64-linux-musl/lib \
        -L /usr/lib \
        -L /usr/local/lib \
        -nostartfiles /usr/local/x86_64-linux-musl/lib/crt1.o \
        /usr/local/lib/gcc/x86_64-linux-musl/6.4.0/crtbegin.o \
        /usr/local/lib/gcc/x86_64-linux-musl/6.4.0/crtend.o \
        -Wl,-dynamic-linker,/usr/local/x86_64-linux-musl/lib/ld-musl-x86_64.so.1 \
        -Wl,-rpath,/usr/local/x86_64-linux-musl/lib,-rpath,/usr/lib,-rpath,/usr/local/lib \
        -nodefaultlibs -stdlib=libc++ -lc++ -lpthread -lc++abi -lunwind -lm -lc
