#!/bin/bash

# console colors
RED='\033[0;31m'
YELLOW='\033[93m'
NC='\033[0m'

# architectures sysroots
AARCH64='aarch64-poky-linux'
ARMV5E='armv5e-poky-linux-gnueabi'
CORTEXA9='cortexa9hf-vfp-neon-poky-linux-gnueabi'
CORTEXA9_SYS='arm-poky-linux-gnueabi'
X86='x86'
ARCH_SET=$AARCH64 #dssip by default

# flags
CONFIGURE=0
CLEAN=0
BUILD=0
TEST=0
SANITIZER=0
DEBUG=0


# log functions
function print_help() {
	 printf "
Usage: build-vds  [OPTIONS]... 
Configure and build vdc in current directory.
	
	--arch=[arch]        	select target architecture, when none aarch64 is set
				[aarch64|armv5|cortexa9|x86]
	--configure|-c 		configure project
	--build|-b		incremental build, default when no arguments 
	--debug|-d		enable build with debug flag
	--rebuild|-rb		rebuild project, ie. make clean and build
	--test|-t		run unit tests
"
	exit
}


function err() {
	echo -e "${RED}ERROR: ${1}"
	echo -ne "${NC}"
}

function notice() {
	msg=${1}
	msg_len=${#msg}
	sep_len=$((($(tput cols)-${msg_len} -2)/2))
	sep=$(printf '%0.s-' $(seq 1 $sep_len)) 
	echo -e "${YELLOW}${sep} ${1} ${sep}${NC}"
	echo -ne "${NC}"
}

function check_err() {
	if [ "$?" -ne "0" ]; then
		err "Operation $1 failed, Exiting..."
		exit
	fi
}

# parse arguments
function parse_args() {
	for arg in "$@"; do
		case "$arg" in 
			--help|-h )
				print_help;;
			--configure|-c )
	  			CONFIGURE=1;;
  			--rebuild|-rb )
				CLEAN=1;&
			--build|-b )
				BUILD=1;;
			--debug|-d )
				DEBUG=1;;
			--test|-t )
				TEST=1;;
			--sanitizer|-s )
				SANITIZER=1;;
			--arch=aarch64 )
				ARCH_SET=$AARCH64;;
			--arch=armv5 )
				ARCH_SET=$ARMV5E;;
			--arch=cortexa9 )
				ARCH_SET=$CORTEXA9;;
			--arch=x86 )
				ARCH_SET=$X86;;
			*)
				err "unknown command $arg"
				print_help;;
		esac
	done
}

# setup toolchain
function source_toolchain() {
        notice "Architecture set $ARCH_SET"
	if [ ! "$ARCH_SET" == "$X86" ]; then
		notice "Source poky toolchain"
        	export CFLAGS=" -g -O0  --sysroot=/opt/poky/2.0.2/sysroots/${ARCH_SET}"
        	export CXXFLAGS=" -g -O0  --sysroot=/opt/poky/2.0.2/sysroots/${ARCH_SET}"
        	export LDFLAGS=" --sysroot=/opt/poky/2.0.2/sysroots/${ARCH_SET}"
        	export CPPFLAGS=" --sysroot=/opt/poky/2.0.2/sysroots/${ARCH_SET}"


		source "/opt/poky/2.0.2/site-config-${ARCH_SET}"
        	source "/opt/poky/2.0.2/environment-setup-${ARCH_SET}"
	fi

	if (( $SANITIZER == 1 )); then
		notice "Sanitizer is enabled"
		SANITIZER_OPTS=' --enable-sanitizer '
	fi
}

# build functions
function configure_poky() {
	if [ $ARCH_SET == $CORTEXA9 ]; then
		HOST_ARCH=$CORTEXA9_SYS
		TARGET_ARCH=$CORTEXA9_SYS
	else
		HOST_ARCH=$ARCH_SET
		TARGET_ARCH=$ARCH_SET
	fi

	local CONF_OPTS="--with-libtool-sysroot=/opt/poky/2.0.2/sysroots/${ARCH_SET} --host=${HOST_ARCH} --build=x86_64-linux --target=${TARGET_ARCH} ${SANITIZER_OPTS}"
	
	if (( $DEBUG == 1 ));then
		CONF_OPTS="${CONF_OPTS} --enable-debug"
	fi

	./configure $CONF_OPTS
}

function configure_x86() {
	./configure ${SANITIZER_OPTS}
}

function configure() {
	notice "Configuring..."
	notice "Changed directory to $(pwd)"
	cd $(pwd)
	
	if [ ! "$ARCH_SET" == "$X86" ]; then
		configure_poky
	else
		configure_x86
	fi

	check_err "configure"
}

function make_clean() {
	notice "Cleaning project..."
	make clean
	check_err "make_clean"
}

function build() {
	notice "Building..."
	make -j4
	check_err "build"
}

function build_test() {
	notice "Building test..."
		make test
		check_err "test build"

}

function run_test() {
	build_test
	
	notice "Testing..."
	./test
}

#run script
parse_args "$@"
source_toolchain

if (( $CONFIGURE != 1 )) && \
	(( $CLEAN != 1 )) && \
       	(( $BUILD != 1)) && \
	(( $TEST !=1 )); then
	BUILD=1 # if no build params, run incremental build
fi


if (( $CONFIGURE ==  1 )); then 
	configure
fi

if (( $CLEAN ==  1 )); then 
        make_clean
fi

if (( $BUILD ==  1 )); then 
        build
fi

if (( $TEST == 1 )); then
	run_test
fi

#!/bin/bash

# console colors
RED='\033[0;31m'
