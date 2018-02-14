#CMakeLists.txt for fba
# (c) 2018 tumu, MIT License

#on msvc, make sure you have the CMakeSettings.json as well

# WARNING because of globbing, if you add/remove files or svn/git to different branches, remember to run cmake again
# or your file changes will not be included in the project builds, making builds fail without clear reason.

#xenial lts has 3.5 without list filter, so workaround that
#source_group TREE is in 3.8+, ifdef it out
cmake_minimum_required(VERSION 3.5)

# if you're not sure what cmake does
#set(CMAKE_VERBOSE_MAKEFILE TRUE)

# lets keep old stuff away
set(CMAKE_ERROR_DEPRECATED TRUE)

#msvc groks this, others ignore
#fix kaillera get foreach this before allowing multiconf
#set(CMAKE_CONFIGURATION_TYPES "Debug;Release")

# we don't manual compile intermediates
set(CMAKE_SKIP_PREPROCESSED_SOURCE_RULES TRUE)
set(CMAKE_SKIP_ASSEMBLY_SOURCE_RULES TRUE)
# can use this if you don't touch build rules
#set(CMAKE_SKIP_RULE_DEPENDENCY TRUE)

#TODO use the version instead of build_details.exe
project(fba VERSION 0.2.97.42)

# main compile settings
#NOTE affects all subprojects, including libs (png, zlib, 7z)
#NOTE do not include cmake defaults, we want our own

#gcc 4.8.2 does not support tree verbose
#old: -ftree-vectorizer-verbose=3
#new: -fopt-info-vec-optimized -fopt-info-vec-missed (or -fopt-info-vec-all)
#if using old gcc without simd/autovec, try -mpreferred-stack-boundary=2 to help cache usage
set(FLAGS_TREE_VEC "-ftree-vectorize -fvect-cost-model=cheap") # -fopt-info-vec-optimized -fopt-info-vec-missed")

if (MINGW)
# All x86 64-bit processors have at least SSE2.
#GCC will only use SSE4.1 if you tell it to e.g with -msse4.1 or something higher such as -mavx.
#Note that -msse is also a possibility, but it will only vectorize loops using floats, not doubles or ints.

set(CMAKE_C_FLAGS_DEBUG "-D_DEBUG -msse2 -mfpmath=sse -g -Og -Wall -ffast-math" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELEASE "-DNDEBUG -msse2  -mfpmath=sse -O2 -ffast-math ${FLAGS_TREE_VEC}" CACHE STRING "" FORCE)

set(CMAKE_CXX_FLAGS_DEBUG "-D_DEBUG -msse2 -mfpmath=sse -g -Og -Wall -ffast-math -std=gnu++11" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG -msse2 -mfpmath=sse -O2 -ffast-math -std=gnu++11 ${FLAGS_TREE_VEC}" CACHE STRING "" FORCE)

set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS_RELEASE} CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS_RELEASE} CACHE STRING "" FORCE)
endif()

if (UNIX)
# need -ffast-math or -funsafe-math.. to get NEON opts on armv7
set(CMAKE_C_FLAGS_DEBUG "-D_DEBUG -march=armv7-a -mfpu=neon-vfpv4 -mtune=cortex-a15 -g -Og -Wall -ffast-math" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELEASE "-DNDEBUG -march=armv7-a -mfpu=neon-vfpv4 -mtune=cortex-a15 -O2 -ffast-math ${FLAGS_TREE_VEC}"  CACHE STRING "" FORCE)

#FIXME need the -std for tms cpu (cstdint include)
set(CMAKE_CXX_FLAGS_DEBUG "-D_DEBUG -march=armv7-a -mfpu=neon-vfpv4 -mtune=cortex-a15 -g -Og -Wall -ffast-math -std=gnu++11"  CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG -march=armv7-a -mfpu=neon-vfpv4 -mtune=cortex-a15 -O2 -ffast-math -std=gnu++11 ${FLAGS_TREE_VEC}" CACHE STRING "" FORCE)

set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS_RELEASE} CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS_RELEASE} CACHE STRING "" FORCE)
endif()

if (MSVC)

set(CMAKE_C_FLAGS_DEBUG "-D_DEBUG")
set(CMAKE_C_FLAGS_RELEASE "-DNDEBUG /Qvec-report:2")

set(CMAKE_CXX_FLAGS_DEBUG "-D_DEBUG")
# /Os should turn autovec off
set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG /Qvec-report:2")
endif()

set_property(GLOBAL PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

function(single_folder return_list)
	list(APPEND folders ${ARGV})
	list(REMOVE_AT folders 0)
	list(REMOVE_DUPLICATES folders)

	foreach(dep IN LISTS folders)
		file(GLOB file_list ${CMAKE_SOURCE_DIR}/src/${dep}/*.c ${CMAKE_SOURCE_DIR}/src/${dep}/*.cpp)
		file(GLOB header_list ${CMAKE_SOURCE_DIR}/src/${dep}/*.h)

		string(REPLACE "/" "\\" sub_group ${dep})

		if (MSVC)
			source_group("${sub_group}" FILES ${file_list})
			source_group("${sub_group}\\_hdr" FILES ${header_list})
		endif()
		list(APPEND filelist ${file_list})
		list(APPEND filelist ${header_list})

    endforeach(dep)

	SET(${return_list} ${filelist} PARENT_SCOPE)
endfunction(single_folder)

FUNCTION(recurse_folder search_path return_list)
	FILE(GLOB_RECURSE new_list ${CMAKE_SOURCE_DIR}/src/${search_path}/*.c ${CMAKE_SOURCE_DIR}/src/${search_path}/*.cpp)
	FILE(GLOB_RECURSE header_list ${CMAKE_SOURCE_DIR}/src/${search_path}/*.h)

	foreach(header_path ${header_list})
		GET_FILENAME_COMPONENT(dir_path ${header_path} DIRECTORY)
		string(REPLACE ${CMAKE_SOURCE_DIR}/src/ "" stripped_path ${dir_path})
		string(REPLACE "/" "\\" sub_group ${stripped_path})
		if (MSVC)
			source_group(TREE ${dir_path} PREFIX ${sub_group}\\_hdr FILES ${header_path})
		endif()
	endforeach()

	if (MSVC)
		source_group(TREE ${CMAKE_SOURCE_DIR}/src/${search_path} PREFIX ${search_path} FILES ${new_list})
	endif()
	list(APPEND new_list ${header_list})
 
	SET(${return_list} ${new_list} PARENT_SCOPE)
ENDFUNCTION(recurse_folder)

#drop-in for missing list filter in cmake 3.5.1
FUNCTION(exclude_regex dummy1 return_list dummy2 dummy3 regx)
	foreach(item IN LISTS ${return_list})
		if(item MATCHES ${regx})
			list(REMOVE_ITEM ${return_list} ${item})
		endif()
	endforeach()

	SET(${return_list} ${${return_list}} PARENT_SCOPE)
endfunction()

# gather list of drvs for gamelist.pl arg
FUNCTION(get_drvs_for_gamelist return_list)
	#just glob the folder list
	FILE(GLOB drv_list RELATIVE ${CMAKE_SOURCE_DIR}/src/burn/drv/ ${CMAKE_SOURCE_DIR}/src/burn/drv/*)
	exclude_regex(FILTER drv_list EXCLUDE REGEX .cpp$)
	list(SORT drv_list)

	SET(${return_list} ${drv_list} PARENT_SCOPE)
ENDFUNCTION(get_drvs_for_gamelist)

if (WIN32)
single_folder(single_list
				"burner"
				"burner/win32"
				"intf"
				"intf/audio"
				"intf/audio/win32"
				"intf/cd"
				"intf/cd/win32"
				"intf/input"
				"intf/input/win32"
				"intf/perfcount"
				"intf/perfcount/win32"
				"intf/video"
				"intf/video/win32"
				"intf/video/scalers"
				"dep/kaillera/client"
				)
else()
#UNIX AND NOT APPLE
single_folder(single_list
				"burner"
				"burner/sdl"
				"intf"
				"intf/audio"
				"intf/audio/sdl"
				"intf/cd"
				"intf/cd/sdl"
				"intf/input"
				"intf/input/sdl"
				"intf/video"
				"intf/video/sdl"
				"intf/video/scalers"
				)
# unfinished stubs for other plats
#				"intf/perfcount"
# needs c++11 compile
#				"intf/audio/linux"
# avoid opengl on generic unix
#				"intf/video/opengl"
endif()

recurse_folder("burn" burnlist)
recurse_folder("cpu" cpulist)

# remove not so few sources used as includes
# FIXME set_source_files_properties() is supposed to work, but didn't.. :(
#set_source_files_properties(HEADER_FILE_ONLY ON)

exclude_regex(FILTER single_list EXCLUDE REGEX burner/win32/resource.h$)
exclude_regex(FILTER single_list EXCLUDE REGEX burner/win32/resource_string.h$)
if (MINGW)
exclude_regex(FILTER single_list EXCLUDE REGEX intf/video/scalers/hq_shared32.cpp$)
exclude_regex(FILTER single_list EXCLUDE REGEX intf/video/scalers/hq3xs.cpp$)
endif()

if (UNIX)
exclude_regex(FILTER single_list EXCLUDE REGEX intf/video/scalers/hq_shared32.cpp$)
exclude_regex(FILTER single_list EXCLUDE REGEX intf/video/scalers/hq3xs.cpp$)

#win only protos
exclude_regex(FILTER single_list EXCLUDE REGEX burner/state.cpp$)
# does not compile
exclude_regex(FILTER single_list EXCLUDE REGEX burner/un7z.cpp$)
# needs gl dev includes
exclude_regex(FILTER single_list EXCLUDE REGEX intf/video/sdl/vid_sdlopengl.cpp$)
# cpp+unicode issues
exclude_regex(FILTER burnlist EXCLUDE REGEX drv/midway/d_kinst.cpp$)
endif()

# includes
exclude_regex(FILTER cpulist EXCLUDE REGEX ops\.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX tbl\.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX v60/[a-z0-9]+\.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX instr\.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX sfr\.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX m6502/[a-z0-9]+\.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX arm7core\.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX arm7exec\.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX 6280\.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX m68kfpu\.c$)
# dasms
exclude_regex(FILTER cpulist EXCLUDE REGEX dasm\.cpp$)
exclude_regex(FILTER cpulist EXCLUDE REGEX dasm\.c$)

# FIXME not doing x64 now
exclude_regex(FILTER cpulist EXCLUDE REGEX /mips3/x64/)

#not doing gens here
exclude_regex(FILTER cpulist EXCLUDE REGEX a68k/fba_make68k.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX a68k/mips/fba_make68k.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX m68k/m68kmake.c$)
exclude_regex(FILTER cpulist EXCLUDE REGEX m68k/m68k_in.c$)
exclude_regex(FILTER burnlist EXCLUDE REGEX drv/pgm/pgm_sprite_create.cpp$)
exclude_regex(FILTER burnlist EXCLUDE REGEX drv/capcom/ctv_make.cpp$)

list(APPEND SRCS ${single_list} ${burnlist} ${cpulist})

#libs
set(LIB_DIR src/dep/libs)

#lib7z does not compile on xenial lts
if (NOT UNIX)
file(GLOB LIB7Z_CXX ${LIB_DIR}/lib7z/*.c)
file(GLOB LIB7Z_HDR ${LIB_DIR}/lib7z/*.h)
add_library(7z STATIC ${LIB7Z_CXX} ${LIB7Z_HDR})
endif()

file(GLOB LIBPNG_CXX ${LIB_DIR}/libpng/*.c)
file(GLOB LIBPNG_HDR ${LIB_DIR}/libpng/*.h)
add_library(png STATIC ${LIBPNG_CXX} ${LIBPNG_HDR})

file(GLOB ZLIB_CXX ${LIB_DIR}/zlib/*.c)
file(GLOB ZLIB_HDR ${LIB_DIR}/zlib/*.h)
add_library(zlib STATIC ${ZLIB_CXX} ${ZLIB_HDR})

set (GEN_DIR ${CMAKE_SOURCE_DIR}/src/dep/generated)
file(MAKE_DIRECTORY ${GEN_DIR})

#set(USE_PERL_GENS 1)
if (USE_PERL_GENS)
macro(perlgen _gen _out _in)
add_custom_command(OUTPUT ${GEN_DIR}/${_out}
COMMAND perl ARGS src/dep/scripts/${_gen}.pl -o src/dep/generated/${_out} ${_in}
DEPENDS ${_in}
WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
endmacro()

perlgen(license2rtf license.rtf src/license.txt)
perlgen(cave_sprite_func cave_sprite_func.h "")
perlgen(cave_tile_func cave_tile_func.h "")
perlgen(neo_sprite_func neo_sprite_func.h "")
perlgen(psikyo_tile_func psikyo_tile_func.h "")
perlgen(toa_gp9001_func toa_gp9001_func.h "")

get_drvs_for_gamelist(drvlist)
add_custom_command(OUTPUT ${GEN_DIR}/driverlist.h
COMMAND perl ARGS ../../dep/scripts/gamelist.pl -o ../../dep/generated/driverlist.h -l ../../gamelist.txt ${drvlist}
WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/src/burn/drv)

else()
add_custom_command(OUTPUT 
${GEN_DIR}/license.rtf
${GEN_DIR}/cave_sprite_func.h
${GEN_DIR}/cave_tile_func.h
${GEN_DIR}/neo_sprite_func.h
${GEN_DIR}/psikyo_tile_func.h
${GEN_DIR}/toa_gp9001_func.h
COMMAND ${CMAKE_COMMAND} -D GEN_DIR:PATH=src/dep/generated -P generators.cmake
DEPENDS src/license.txt
WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

#TODO add every driver as dep
add_custom_command(OUTPUT 
${GEN_DIR}/driverlist.h
COMMAND ${CMAKE_COMMAND} -D GEN_DIR:PATH=src/dep/generated -D DO_DRIVERLIST=1 -P generators.cmake
WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

endif()

list(APPEND GENERATED
${GEN_DIR}/driverlist.h
${GEN_DIR}/license.rtf
${GEN_DIR}/cave_sprite_func.h
${GEN_DIR}/cave_tile_func.h
${GEN_DIR}/neo_sprite_func.h
${GEN_DIR}/psikyo_tile_func.h
${GEN_DIR}/toa_gp9001_func.h
)

if (MINGW)
add_custom_command(OUTPUT 
${GEN_DIR}/app_gnu.rc
COMMAND ${CMAKE_COMMAND} -D GEN_DIR:PATH=src/dep/generated -D DO_APPGNURC=1 -P generators.cmake
DEPENDS src/burner/win32/app.rc
WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
endif()

add_executable(build_details src/dep/scripts/build_details.cpp)
add_custom_command(OUTPUT ${GEN_DIR}/build_details.h
COMMAND build_details ARGS > ${GEN_DIR}/build_details.h)

add_executable(pgm_sprite_create src/burn/drv/pgm/pgm_sprite_create.cpp)
add_custom_command(OUTPUT ${GEN_DIR}/pgm_sprite.h
COMMAND pgm_sprite_create ARGS > ${GEN_DIR}/pgm_sprite.h)

add_executable(ctv src/burn/drv/capcom/ctv_make.cpp)
add_custom_command(OUTPUT ${GEN_DIR}/ctv.h
COMMAND ctv ARGS > ${GEN_DIR}/ctv.h)

add_executable(m68kmake src/cpu/m68k/m68kmake.c)
target_compile_definitions(m68kmake PRIVATE INLINE="__inline static")
add_custom_command(OUTPUT ${GEN_DIR}/m68kops.h ${GEN_DIR}/m68kops.c
COMMAND m68kmake ARGS ${GEN_DIR} ${CMAKE_SOURCE_DIR}/src/cpu/m68k/m68k_in.c)

list(APPEND GENERATED
${GEN_DIR}/build_details.h
${GEN_DIR}/pgm_sprite.h
${GEN_DIR}/ctv.h
${GEN_DIR}/m68kops.h
${GEN_DIR}/m68kops.c
)

if(MINGW)
#https://msdn.microsoft.com/en-us/library/windows/desktop/dd317756(v=vs.85).aspx
#1252	windows-1252	ANSI Latin 1; Western European (Windows)
#65001	utf-8	Unicode (UTF-8)
# pragma code_page() 
#This pragma is not supported in an included resource file (.rc).
#RC does not support the ANSI C predefined macros (__DATE__, __FILE__, __LINE__, __STDC__, __TIME__, __TIMESTAMP__). 
#RC does define RC_INVOKED, which enables you conditionally compile portions of your header files
#RC treats files with the .c and .h extensions in a special manner. It assumes that a file with one of these extensions does not contain resources.
#If a file has the .c or .h file name extension, RC ignores all lines in the file except the preprocessor directives.

add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/resource.rc.obj
COMMAND windres ARGS -c 1252 -F pe-i386 -D_WIN32 -DUNICODE -DINCLUDE_AVI_RECORDING -Isrc/burn -Isrc/burner -Isrc/burner/win32 -Isrc/dep/generated -Isrc/intf/video/win32 src/burner/win32/resource.rc ${CMAKE_BINARY_DIR}/resource.rc.obj
WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
DEPENDS ${GEN_DIR}/build_details.h ${GEN_DIR}/license.rtf src/burner/win32/app.rc src/burner/title.h src/burner/win32/resource_string.h src/burner/win32/version.rc src/burner/win32/string.rc$ ${GEN_DIR}/app_gnuc.rc
MAIN_DEPENDENCY src/burner/win32/resource.rc
)

add_library(resource STATIC ${CMAKE_BINARY_DIR}/resource.rc.obj)

# cmake doesn't know the format of resource.rc.obj
SET_TARGET_PROPERTIES(resource PROPERTIES LINKER_LANGUAGE CXX)
endif()

if (MSVC)
# not really generated
list(APPEND GENERATED ${CMAKE_SOURCE_DIR}/src/burner/win32/resource.rc)

source_group(_generated FILES ${GENERATED})
endif()


# final exe, depend on prebuild files
add_executable(${PROJECT_NAME} WIN32 ${SRCS} ${GENERATED})

if (MINGW)
# whole archive resource or it gets left out as nothing directly refers it
target_link_libraries(${PROJECT_NAME} -Wl,--whole-archive resource -Wl,--no-whole-archive)
endif()

if (WIN32)
target_link_libraries(${PROJECT_NAME} 7z)
endif()

target_link_libraries(${PROJECT_NAME} png zlib)

if (UNIX)
find_program(SDLCONFIG sdl-config
	PATHS ../sdlinst/bin ENV SDL_CONFIG)
# ask sdl what it links against, so we don't blow up our linking
execute_process(COMMAND ${SDLCONFIG} --static-libs
	OUTPUT_VARIABLE SDLSTATICLIBS
	OUTPUT_STRIP_TRAILING_WHITESPACE)
target_link_libraries(${PROJECT_NAME} ${SDLSTATICLIBS}) 
endif()

if (WIN32)
target_link_libraries(${PROJECT_NAME} comctl32.lib winmm.lib shlwapi.lib setupapi.lib wininet.lib vfw32.lib)
#user32.lib gdi32.lib comdlg32.lib shell32.lib ole32.lib advapi32.lib
endif()

if (MSVC)
target_link_libraries(${PROJECT_NAME} xaudio2.lib)
endif()

target_include_directories(${PROJECT_NAME} PRIVATE 
src/cpu
src/cpu/i8039
src/cpu/m68k
src/cpu/tms32010
src/cpu/upd7725
src/cpu/i8051
src/cpu/upd7810
src/cpu/v60
src/burn/devices
src/burn/drv/konami
src/burn/drv/sega
src/burn/drv/taito
src/burn/drv/capcom
src/burn/drv/cave
src/burn/drv/neogeo
src/burn/drv/psikyo
src/burn/drv/toaplan
src/burn/snd
src/intf/audio
src/intf/input
src/intf/video
src/intf/video/scalers
src/intf/cd
src/intf
src/burner
src/burn
src/dep/generated
)
if (WIN32)
target_include_directories(${PROJECT_NAME} PRIVATE 
src/intf/audio/win32
src/intf/video/win32
src/burner/win32
src/dep/kaillera/client
src/dep/vc/include
src/dep/mingw/include/directx9
)
# sal.h in here overrides sdk sal.h and breaks build
#src/dep/mingw/include/xaudio2
endif()

if (MINGW)
target_include_directories(${PROJECT_NAME} PRIVATE 
src/dep/mingw/include
src/dep/mingw/include/xaudio2
src/dep/mingw/dx80_mgw/include
)
endif()

#FIXME don't include sdl like this
if (UNIX)
target_include_directories(${PROJECT_NAME} PRIVATE 
src/burner/sdl
src/dep/libs/libsdl/include
)
endif()

if (WIN32)
include_directories(
src/dep/libs/lib7z
)
endif()

include_directories(
src/dep/libs/libpng
src/dep/libs/zlib
)

target_compile_definitions(${PROJECT_NAME} PRIVATE
LSB_FIRST
INCLUDE_LIB_PNGH
INCLUDE_AVI_RECORDING
)

if (WIN32)
target_compile_definitions(${PROJECT_NAME} PRIVATE
_UNICODE
UNICODE
BUILD_WIN32
INCLUDE_7Z_SUPPORT
KAILLERA_DLL
)
endif()

# to get burner_sdl.h included
if (UNIX)
target_compile_definitions(${PROJECT_NAME} PRIVATE
BUILD_SDL
__fastcall=
)
endif()

#set(KAILLERA_DLL 1)
# get kaillera dll if building with it
if(KAILLERA_DLL AND WIN32)
if(NOT EXIST ${CMAKE_SOURCE_DIR}/src/dep/kaillera/kaillera-0.9-sdk.zip)
	file(DOWNLOAD http://www.kaillera.com/files/kaillera-0.9-sdk.zip ${CMAKE_SOURCE_DIR}/src/dep/kaillera/kaillera-0.9-sdk.zip
	EXPECTED_HASH MD5=349c9178bd96be33e77612b1ce5cd181
	SHOW_PROGRESS)
endif()
# run at gen
if (MSVC)
set(EXTRACT_DIR ${CMAKE_BINARY_DIR}/${CMAKE_CONFIGURATION_TYPES})
else()
set(EXTRACT_DIR ${CMAKE_BINARY_DIR})
endif()
execute_process(COMMAND ${CMAKE_COMMAND} -E tar xz "${CMAKE_SOURCE_DIR}/src/dep/kaillera/kaillera-0.9-sdk.zip"
	WORKING_DIRECTORY ${EXTRACT_DIR})
endif()

# get minimal dx80 sdk for mingw
if (MINGW)
if(NOT EXIST ${CMAKE_SOURCE_DIR}/src/dep/mingw/dx80_mgw.zip)
	file(DOWNLOAD http://download.tuxfamily.org/allegro/files/dx80_mgw.zip ${CMAKE_SOURCE_DIR}/src/dep/mingw/dx80_mgw.zip
	EXPECTED_HASH MD5=56989db41e494786220ed4e4788af929
	SHOW_PROGRESS)

	set(EXTRACT_DIR ${CMAKE_SOURCE_DIR}/src/dep/mingw/dx80_mgw)
	file(MAKE_DIRECTORY ${EXTRACT_DIR})

	execute_process(COMMAND ${CMAKE_COMMAND} -E tar xz "${CMAKE_SOURCE_DIR}/src/dep/mingw/dx80_mgw.zip"
		WORKING_DIRECTORY ${EXTRACT_DIR})
endif()
endif()

if(MINGW)
target_compile_options(${PROJECT_NAME} PUBLIC -Wno-write-strings)
endif()

if (UNIX)
target_compile_options(${PROJECT_NAME} PUBLIC -Wno-write-strings)
# libpng in fba is missing arm srcs or disable -mfpu=neon on libpng
target_compile_definitions(png PRIVATE PNG_ARM_NEON_OPT=0)
endif()

if (MSVC)
# we're not using secure crt funcs anytime soon
target_compile_definitions(${PROJECT_NAME} PRIVATE _CRT_SECURE_NO_WARNINGS)
target_compile_definitions(png PRIVATE _CRT_SECURE_NO_WARNINGS)
target_compile_definitions(zlib PRIVATE _CRT_SECURE_NO_WARNINGS)

# turn extra runtime checks off
#fixme should use /TC but fba uses bool typedef
target_compile_options(${PROJECT_NAME} PUBLIC /GS- /fp:fast /Oy /GR-)
target_compile_options(7z PUBLIC /GS- /fp:fast /Oy)
#C4996 posix name is deprec
target_compile_options(zlib PUBLIC /GS- /fp:fast /Oy /wd4996)
target_compile_options(png PUBLIC /GS- /fp:fast /Oy)
endif()

