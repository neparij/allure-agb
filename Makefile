TARGET      	:=  $(notdir $(CURDIR))
BUILD       	:=  build
LIBBUTANO   	:=  ../butano.official/butano
PYTHON      	:=  python3
SOURCES     	:=  include \
					src \
					src/examples \
					src/examples/suites \
					../butano.official/common/src
INCLUDES    	:=  include \
					../butano.official/butano/include \
					../butano.official/common/include
DATA        	:=
GRAPHICS    	:=  ../butano.official/common/graphics
AUDIO       	:=
DMGAUDIO    	:=
ROMTITLE    	:=  ALLUREGBA
ROMCODE     	:=  NPAR
USERFLAGS   	:=  -std=gnu11
USERCXXFLAGS	:=
USERASFLAGS 	:=
USERLDFLAGS 	:=
USERLIBDIRS 	:=
USERLIBS    	:=
DEFAULTLIBS 	:=
STACKTRACE		:=
USERBUILD   	:=
EXTTOOL     	:=

ifndef LIBBUTANOABS
	export LIBBUTANOABS	:=	$(realpath $(LIBBUTANO))
endif

include $(LIBBUTANOABS)/butano.mak
