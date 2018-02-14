# generators.cmake
# (c) 2018 tumu, MIT License

function(cave_sprite_func)

file(WRITE "${GEN_DIR}/cave_sprite_func.h" "")
file(WRITE "${GEN_DIR}/cave_sprite_func_table.h" "")

macro(out_func _str)
file(APPEND "${GEN_DIR}/cave_sprite_func.h" ${_str})
endmacro()
macro(out_tabl _str)
file(APPEND "${GEN_DIR}/cave_sprite_func_table.h" ${_str})
endmacro()

out_func("#define EIGHTBIT 1\n")
out_func("#define ROT 0\n\n")
out_func("#define BPP 16\n")

out_tabl("// Table with all function addresses.\n")
out_tabl("static RenderSpriteFunction RenderSpriteFunctionTable[] = {\n")

# gen cave tables and funcs
list(APPEND zbuffer "_NOZBUFFER" "_RZBUFFER" "_WZBUFFER" "_RWZBUFFER")
foreach(Size RANGE 320 384 64)
	out_func("#define XSIZE ${Size}\n")

	set(FunctionName "&RenderSprite16_${Size}_ROT0")

	# No scaling
	out_func("#define ZOOM 0\n")

	foreach(Function RANGE 7)

		math(EXPR x "${Function} & 3")
		if (NOT x)
			math(EXPR r "(${Function} & 4) / 4")
			out_func("#define XFLIP ${r}\n")

			math(EXPR f "${Function} & 4")
			if (NOT f)
				set(Flip "_NOFLIP")
			else()
				set(Flip "_FLIPX")
			endif()

			out_tabl("\t")
		endif()

		out_func("#define ZBUFFER ${x}\n")
		out_func("#include \"cave_sprite_render.h\"\n")
		list(GET zbuffer ${x} zres)
		out_tabl("${FunctionName}${Flip}_NOZOOM_CLIPX${zres}_256, ")

		out_func("#undef ZBUFFER\n")

		if (x EQUAL 3)
			out_func("#undef XFLIP\n")

			out_tabl("\n")
		endif()
	endforeach()

	out_func("#undef ZOOM\n\n")

	# Scale up/down

	out_func("#define XFLIP 0\n")

	foreach(Function RANGE 7)

		math(EXPR x "${Function} & 3")
		if (NOT x)
			math(EXPR r "1 + (${Function} & 4) / 4")
			out_func("#define ZOOM ${r}\n")

			math(EXPR r "${Function} & 4")
			if (NOT r)
				set(Zoom "_ZOOMOUT")
			else()
				set(Zoom "_ZOOMIN")
			endif()
		endif()

		out_func("#define ZBUFFER ${x}\n")
		out_func("#include \"cave_sprite_render_zoom.h\"\n")
		out_func("#undef ZBUFFER\n")

		list(GET zbuffer ${x} zres)
		out_tabl("${FunctionName}_NOFLIP${Zoom}_NOCLIP${zres}_256, ")

		if (x EQUAL 3)
			out_func("#undef ZOOM\n\n")

			out_tabl("\n")
		endif()
	endforeach()
		
	out_func("#undef XFLIP\n")
	out_func("#undef XSIZE\n\n")

endforeach()

out_func("#undef BPP\n\n")
out_func("#undef ROT\n\n")
out_func("#undef EIGHTBIT\n\n")

out_tabl("}\;\n\n")

out_func("#include \"cave_sprite_func_table.h\"\n")

out_tabl("static RenderSpriteFunction* RenderSprite_ROT0[2] = {\n\t&RenderSpriteFunctionTable[0],\n\t&RenderSpriteFunctionTable[16]\n}\;\n")

endfunction()

function(cave_tile_func)

file(WRITE "${GEN_DIR}/cave_tile_func.h" "")
file(WRITE "${GEN_DIR}/cave_tile_func_table.h" "")

macro(out_func _str)
file(APPEND "${GEN_DIR}/cave_tile_func.h" ${_str})
endmacro()
macro(out_tabl _str)
file(APPEND "${GEN_DIR}/cave_tile_func_table.h" ${_str})
endmacro()

out_func("#define XFLIP 0\n")
out_func("#define YFLIP 0\n")
out_func("#define ROT 0\n\n")
out_func("#define BPP 16\n")

out_tabl("// Table with all function addresses.\n")
out_tabl("static RenderTileFunction RenderTileFunctionTable[] = {\n")

foreach(Size RANGE 320 384 64)

	out_func("#define XSIZE ${Size}\n")
	out_func("#define EIGHTBIT 1\n")

	set(FunctionName "&RenderTile16_${Size}_ROT0_NOFLIP")

	foreach(Function RANGE 2)
		math(EXPR x "${Function} & 1")
		if (x EQUAL 0)
			set(RowScroll "_NOROWSCROLL")

			math(EXPR y "${Function} & 2")
			if (y EQUAL 0)
				set(RowSelect "_NOROWSELECT")
			else()
				set(RowSelect "_ROWSELECT")
			endif()
		else()
			set(RowScroll "_ROWSCROLL")
		endif()

		out_func("#define ROWSCROLL ${x}\n")
		math(EXPR r "(${Function} & 2) / 2")
		out_func("#define ROWSELECT ${r}\n")

		out_tabl("\t")

		out_func("#define DOCLIP 0\n")
		out_func("#include \"cave_tile_render.h\"\n")
		out_func("#undef DOCLIP\n")

		out_tabl("${FunctionName}${RowScroll}${RowSelect}_NOCLIP_256, ")

		out_func("#define DOCLIP 1\n")
		out_func("#include \"cave_tile_render.h\"\n")
		out_func("#undef DOCLIP\n")

		out_tabl("${FunctionName}${RowScroll}${RowSelect}_CLIP_256, ")

		out_func("#undef ROWSELECT\n")
		out_func("#undef ROWSCROLL\n")

		out_tabl("\n")
	endforeach()

	out_func("#undef EIGHTBIT\n\n")
	out_func("#undef XSIZE\n\n")
endforeach()

out_func("#undef BPP\n\n")
out_func("#undef ROT\n\n")
out_func("#undef YFLIP\n")
out_func("#undef XFLIP\n\n")

out_tabl("}\;\n\n")

out_func("#include \"cave_tile_func_table.h\"\n")

out_tabl("static RenderTileFunction* RenderTile_ROT0[2] = {\n\t&RenderTileFunctionTable[0],\n\t&RenderTileFunctionTable[6]\n}\;\n")
endfunction()

function(neo_sprite_func)

file(WRITE "${GEN_DIR}/neo_sprite_func.h" "")
file(WRITE "${GEN_DIR}/neo_sprite_func_table.h" "")

macro(of _str)
file(APPEND "${GEN_DIR}/neo_sprite_func.h" ${_str})
endmacro()
macro(ot _str)
file(APPEND "${GEN_DIR}/neo_sprite_func_table.h" ${_str})
endmacro()

ot("// Table with all function addresses.\n")
ot("static RenderBankFunction RenderBankFunctionTable[] = {\n")

of("#define ISOPAQUE 0\n\n")

foreach(Bitdepth RANGE 16 32 8)
	of("// ${Bitdepth}-bit rendering functions.\n")
	of("#define BPP ${Bitdepth}\n\n")

	set(FunctionName "&RenderBank${Bitdepth}")

	foreach(Function RANGE 31)
		math(EXPR x "${Function} & 15")
		if (x EQUAL 0)
			math(EXPR y "${Function} & 16")
			math(EXPR div "${y} / 16")
			of("#define DOCLIP ${div}\n")

			if (y EQUAL 0)
				set(DoClip "_NOCLIP")
			else()
				set(DoClip "_CLIP")
			endif()
			ot("\t")
		endif()

		of("#define XZOOM ${x}\n")
		of("#include \"neo_sprite_render.h\"\n")
		of("#undef XZOOM\n")

		ot("${FunctionName}_ZOOM${x}${DoClip}_TRANS, ")

		if (x EQUAL 15)
			of("#undef DOCLIP\n")

			ot("\n")
		endif()

	endforeach()

	of("#undef BPP\n\n")
endforeach()
of("#undef ISOPAQUE\n\n")

of("#include \"neo_sprite_func_table.h\"\n")

ot("}\;\n\n")
ot("static RenderBankFunction* RenderBankNormal[3] = {\n\t&RenderBankFunctionTable[0],\n\t&RenderBankFunctionTable[32],\n\t&RenderBankFunctionTable[64]\n}\;\n")

endfunction()

function(psikyo_tile_func)

file(WRITE "${GEN_DIR}/psikyo_tile_func.h" "")
file(WRITE "${GEN_DIR}/psikyo_tile_func_table.h" "")

macro(of _str)
file(APPEND "${GEN_DIR}/psikyo_tile_func.h" ${_str})
endmacro()
macro(ot _str)
file(APPEND "${GEN_DIR}/psikyo_tile_func_table.h" ${_str})
endmacro()


list(APPEND TransFun 0 15 -1)
list(APPEND TransTab "_TRANS0" "_TRANS15" "_SOLID")

of("#define ROT 0\n")
of("#define BPP 16\n")
of("#define FLIP 0\n")
of("#define ZOOM 0\n")
of("#define ZBUFFER 0\n")
of("\n")

ot("// Table with all function addresses.\n")
ot("static RenderTileFunction RenderTile[] = {\n")

foreach(Function RANGE 5)
	
	math(EXPR x "(${Function} & 6) / 2")
	list(GET TransTab ${x} tab)
	set(FunctionName "&RenderTile16${tab}_NOFLIP_ROT0")

	math(EXPR y "${Function} & 1")
	if (y EQUAL 0)
		set (RowScroll "_NOROWSCROLL")
		list(GET TransFun ${x} fun)
		of("#define TRANS ${fun}\n\n")
	else()
		set (RowScroll "_ROWSCROLL")
	endif()

	of("#define ROWSCROLL ${y}\n")
	ot("\t")

	of("#define DOCLIP 0\n")
	of("#include \"psikyo_render.h\"\n")
	of("#undef DOCLIP\n")

	ot("${FunctionName}${RowScroll}_NOZOOM_NOZBUFFER_NOCLIP, ")

	of("#define DOCLIP 1\n")
	of("#include \"psikyo_render.h\"\n")
	of("#undef DOCLIP\n")

	ot("${FunctionName}${RowScroll}_NOZOOM_NOZBUFFER_CLIP, ")

	of("#undef ROWSCROLL\n")
	if (y EQUAL 1)
		of("\n#undef TRANS\n")
	endif()

	ot("\n")
endforeach()

of("#undef ZBUFFER\n")
of("#undef ZOOM\n")
of("#undef FLIP\n")
of("#undef BPP\n")
of("#undef ROT\n")
of("\n")

ot("}\;\n\n")

of("#include \"psikyo_tile_func_table.h\"\n")


endfunction()

function(toa_gp9001_func)

file(WRITE "${GEN_DIR}/toa_gp9001_func.h" "")
file(WRITE "${GEN_DIR}/toa_gp9001_func_table.h" "")

macro(of _str)
file(APPEND "${GEN_DIR}/toa_gp9001_func.h" ${_str})
endmacro()
macro(ot _str)
file(APPEND "${GEN_DIR}/toa_gp9001_func_table.h" ${_str})
endmacro()

ot("// Table with all function addresses.\n")
ot("static RenderTileFunction RenderTileFunctionTable[] = {\n")

list(APPEND Flip "_NOFLIP" "_FLIPX" "_FLIPY" "_FLIPXY")

foreach(Rot RANGE 0 270 270)

	if (Rot EQUAL 270)
		of("#ifdef DRIVER_ROTATION\n")

		ot("#ifdef DRIVER_ROTATION\n")
	endif()

	of("#define ROT ${Rot}\n\n")
	foreach(Bitdepth RANGE 16 32 8)
		of("// ${Bitdepth}-bit rendering functions.\n")
		of("#define BPP ${Bitdepth}\n\n")

		set (FunctionName "&RenderTile${Bitdepth}_ROT${Rot}")

		foreach (Function RANGE 7)

			math(EXPR x "${Function} & 3")
			if (x EQUAL 0)
				math(EXPR ip "(${Function} & 4) / 4")
				of("#define ISOPAQUE ${ip}\n")

				ot("\t")

				math(EXPR y "${Function} & 4")
				if (y EQUAL 0)
					set (IsOpaque "_TRANS")
				else()
					set (IsOpaque "_OPAQUE")
				endif()
			endif()
			math(EXPR xf "${Function} & 1")
			math(EXPR yf "(${Function} & 2) / 2")
			of("#define XFLIP ${xf}\n")
			of("#define YFLIP ${yf}\n")
            
			of("#define DOCLIP 0\n")
			of("#include \"toa_gp9001_render.h\"\n")
			of("#undef DOCLIP\n")

			list(GET Flip ${x} flipres)
			ot("${FunctionName}${flipres}_NOCLIP${IsOpaque}, ")

			of("#define DOCLIP 1\n")
			of("#include \"toa_gp9001_render.h\"\n")
			of("#undef DOCLIP\n")

			ot("${FunctionName}${flipres}_CLIP${IsOpaque}, ")

			of("#undef YFLIP\n")
			of("#undef XFLIP\n\n")

			if (x EQUAL 3)
				of("#undef ISOPAQUE\n\n")

				ot("\n")
			endif()
		endforeach()
		of("#undef BPP\n\n")
	endforeach()
	
	of("#undef ROT\n\n")

	if (Rot EQUAL 270)
		of("#endif\n")

		ot("#endif\n")
	endif()

endforeach()

of("\n")

ot("}\;\n\n")

of("#include \"toa_gp9001_func_table.h\"\n")

ot("static RenderTileFunction* RenderTile_ROT0[3] = {\n\t&RenderTileFunctionTable[0],\n\t&RenderTileFunctionTable[16],\n\t&RenderTileFunctionTable[32]\n}\;\n")
ot("#ifdef DRIVER_ROTATION\n")
ot("static RenderTileFunction* RenderTile_ROT270[3] = {\n\t&RenderTileFunctionTable[48],\n\t&RenderTileFunctionTable[64],\n\t&RenderTileFunctionTable[80]\n}\;\n")
ot("#endif\n")

endfunction()

function(gamelist)

file(WRITE "${GEN_DIR}/driverlist.h" "")
#file(WRITE "${GEN_DIR}/gamelist.txt" "") #FIXME Path

FILE(GLOB_RECURSE all_drv_src ${CMAKE_SOURCE_DIR}/src/burn/drv/d_*.cpp)

set (count 0)

message(STATUS "Parsing drivers.. (this will take a while)")

foreach(drv_src ${all_drv_src})

	file(STRINGS ${drv_src} drvc ENCODING UTF-8)

	foreach(line IN LISTS drvc)

		if (NOT name AND line MATCHES "^struct[ ]+BurnDriver([D|X]?)[ ]+([^ ]+)")

			# status
			set (status ${CMAKE_MATCH_1})
			
			# name
			set (name ${CMAKE_MATCH_2})
			# drivernames  for working
			# drivernamesD for debug only
			# drivernamesX for excluded

			math(EXPR count "${count} + 1")
			
			math(EXPR mod "${count} % 100")
			if (mod EQUAL 0)
				message(STATUS "Drivers parsed: ${count}")
			endif()
			continue()
		endif()

		if(name)
			#inside struct

			# comment removal
			string(FIND ${line} "//" cpos)
			if (cpos GREATER -1)
				# 0...cpos
				#message("" ${line})
				string(SUBSTRING ${line} 0 ${cpos} line)
				#message("" ${cpos} ${line})
				unset(cpos)
			endif()
			
			string(REGEX REPLACE "[/][*][^*]+[*][/]" "" line ${line})
			
			# whitespace removal
			string(STRIP ${line} stripped)

			string(APPEND driverstr ${stripped})
		endif()
		# decide parsing on quoting
		#if(stripped MATCHES "\"")
				# \" -> "
				#string(REPLACE "\\\\\"" "\"" stripped ${stripped})
				
				#string(REPLACE "\", " "\"\;" com ${stripped})
				#string(REGEX REPLACE "([A-Z0-9])," "\\1;" com "${com}")
				# this matches inside "" strings
				#string(REGEX REPLACE "([A-Z0-9]+)[ ]?," "\\1;" com "${com}")
				
				#string(REGEX REPLACE ",$" ";" com "${com}")
				#string(REGEX REPLACE "([a-z]), ([A-Z])" "\\1;\\2" com "${com}")
			#else()
				# no strings, straight replace
				#string(REPLACE "," "\;" com "${stripped}")
			#endif()

			#string(APPEND DRV_${name} "${com}")

		if (name AND line MATCHES "[}]")
			string(REGEX MATCHALL [[L?"(([^"\\]|\\.)*)"|([A-Z][A-Z0-9_| ]+)]] strings "${driverstr}")
			# get shortname and remove quotes
			list(GET strings 0 shortname)
			string(REGEX MATCH "^\"(.*)\"" foo ${shortname})

			set(driver_${CMAKE_MATCH_1} ${strings})

			# create list for sorting
			string(REGEX MATCH "^(\"[^\"]+\")[, ]+(\"[^\"]+\"|NULL)" cloneparent "${driverstr}")

			if(CMAKE_MATCH_2 STREQUAL "NULL")
				#driver is a parent, no clone string
				set(parent ${CMAKE_MATCH_1})
				set(clone [[""]])
			else()
				#driver is a clone, parent string incl
				set(parent ${CMAKE_MATCH_2})
				set(clone ${CMAKE_MATCH_1})
			endif()

			list(APPEND sorted "${parent},${clone},${status},${name}")

			unset(name)
			unset(driverstr)
		endif()

	endforeach()

	#for testing
	#break()
endforeach()

message(STATUS "Total drivers parsed: " ${count})
message(STATUS "Generating driverlist.h")
list(SORT sorted)

file(WRITE "${GEN_DIR}/driverlist.h"
"// This file was generated by cmake\n"
"\n"
"#ifndef D\n"
"#define D(x) extern struct BurnDriver BurnDrv ## x;\n"
"#include __FILE__\n"
"#undef D\n"
"#endif\n"
"\n"
"#ifndef D\n"
"#define D(x) &BurnDrv ## x,\n"
"static struct BurnDriver* pDriver[] = {\n"
"#include __FILE__\n"
"};\n"
"#undef D\n"
"#endif\n"
"\n"
"#ifdef D\n"
)

macro(o _str)
file(APPEND ${GEN_DIR}/driverlist.h ${_str})
endmacro()

foreach(f ${sorted})
	string(REGEX MATCH "^(\"[^\"]+\"),(\"[^\"]*\"),([DX]?),(.*)" foo "${f}")

	if (CMAKE_MATCH_3 STREQUAL "X")
		set(exclude "// ")
	endif()

	if (CMAKE_MATCH_3 STREQUAL "D")
		if (NOT debugflag)
			o("#ifdef FBA_DEBUG\n")
		endif()
		set(debugflag 1)
	endif()

	#o("${exclude}DRV ${CMAKE_MATCH_4}\n")
	string(REPLACE BurnDrv "" r ${CMAKE_MATCH_4})
	o("${exclude}D(${r})\n")
	unset(exclude)

	if (debugflag AND NOT CMAKE_MATCH_3)
		o("#endif\n")
		unset(debugflag)
	endif()

endforeach()

if(debugflag)
	o("#endif\n")
	unset(debugflag)
endif()

o("#endif\n")

message(STATUS "Skip generating gamelist.txt (not done yet)")
#	name            status  full name                                               parent          year    company         hardware        remarks                                 
foreach(f ${sorted})
	string(REGEX MATCH "^\"([^\"]+)\",\"([^\"]*)\",([DX]?),(.*)" foo "${f}")

	set(parent ${CMAKE_MATCH_1})
	set(name ${CMAKE_MATCH_2})
	if (CMAKE_MATCH_3 STREQUAL "X")
		set(exclude "//")
	endif()

	if (CMAKE_MATCH_3 STREQUAL "D")
		set(debugflag 1)
	endif()
	if (debugflag AND NOT CMAKE_MATCH_3)
		unset(debugflag)
	endif()

	if (CMAKE_MATCH_2)
		set(shortname ${CMAKE_MATCH_2})
	else()
		set(shortname ${CMAKE_MATCH_1})
	endif()

	set(drv "${driver_${shortname}}")

	list(GET drv 0 name)
	list(GET drv 4 year)
	list(GET drv 5 fullname_ascii)
	list(GET drv 6 comment)
	list(GET drv 7 manuf)
	list(GET drv 8 system)
	list(GET drv 13 bits)
	
	#message("${name} ${year} ${fullname_ascii} ")

	#o("${exclude}\t&${CMAKE_MATCH_4},\n")

	unset(exclude)


endforeach()

endfunction()


function(license2rtf)

set(Font "Tahoma")
set(FontSize 16)

#set (escape 0)

set(FontFamilies "Tahoma" "swiss" "Times New Roman" "roman")

list(FIND FontFamilies ${Font} findex)
if(findex EQUAL -1)
	set(findex 0)
endif()
math(EXPR findex "${findex} + 1")
list(GET FontFamilies ${findex} rtffont)

# without newline_consume, file strings eats empty lines
file(STRINGS "${CMAKE_SOURCE_DIR}/src/license.txt" txt ENCODING UTF-8)

file(WRITE ${CMAKE_SOURCE_DIR}/src/dep/generated/license.rtf
[[{\rtf1\ansi\ansicpg1252\deff0{\fonttbl(\f0\f]] ${rtffont}
[[\fprq2 ]] ${Font}
[[;)}{\colortbl\red0\green0\blue0;\red255\green0\blue0;\red0\green0\blue191;}\deflang1033\horzdoc\fromtext\pard\plain\f0\fs]] 
${FontSize})

# use "in lists" or you'll have bad time with empty lines
foreach(line IN LISTS txt)

	string(APPEND line "\\par")
	
	# if a paragraph starts with " - " treat it as a bulleted paragraph
	if (line MATCHES "^ - (.*)")
		set(line "\\pard{\\*\\pn\\pnlvlblt\\pnindent0{\\pntxtb\\'B7}}\\fi-144\\li144 ${CMAKE_MATCH_1}\\pard")
		endif()

	# highlight URLs
	string(REGEX REPLACE "(http[s]?:[/]{2}[A-Za-z0-9_~/.-]*)" "\\\\cf2 \\1\\\\cf0" line "${line}")
	
	# if a paragraph starts with "DISCLAIMER:" make the text bold and red
	if (line MATCHES "^DISCLAIMER")
		set(line "\\cf1\\b ${line}\\b0\\cf0")
	endif()

	# if a paragraph starts with a quote make the text italic
	if (line MATCHES "^\"")
		set(line "\\i ${line}\\i0")
	endif()

#	if (escape)
		# Escape quotes and backslashes
		# NOTE can't see how this will work as it will escape rtf tokens
#		string(REGEX REPLACE [[(["\])]] "\\\\\\1" line ${line})
#	endif()

	file(APPEND ${CMAKE_SOURCE_DIR}/src/dep/generated/license.rtf "${line} ")
endforeach()

file(APPEND ${CMAKE_SOURCE_DIR}/src/dep/generated/license.rtf "}")
endfunction()

function(fixup_apprc)
# fixup app.rc for gnu
# custom run windres as cmake fuxes up the cmdline for it

# strings terminates on \n, need to add it back on write
file(STRINGS ${CMAKE_SOURCE_DIR}/src/burner/win32/app.rc apprc ENCODING UTF-8)
file(REMOVE ${GEN_DIR}/app_gnuc.rc)
file(APPEND ${GEN_DIR}/app_gnuc.rc "#include <richedit.h>\n")

foreach(line ${apprc})
	# Fix FONT statements (remove rubbish after font name)
	# NOTE windres 2.28 does not care about the rubbish
	# windres 2.18 (2011 vintage) is probably the min required as it added in codepage support and new resource types
	string(REGEX REPLACE "(FONT .+\").*" "\\1" line ${line})

	# check for invalid window styles
	string(FIND ${line} WS_CHILD foundchild)
	string(FIND ${line} WS_POPUP foundpopup)
	if (${foundchild} GREATER -1 AND ${foundpopup} GREATER -1)
		message("FIXME An app.rc style is using mutually exclusive WS_CHILD and WS_POPUP!")
		message(${line})
	endif()

	file(APPEND ${GEN_DIR}/app_gnuc.rc ${line} "\n")
endforeach()
endfunction()


if (DO_DRIVERLIST)
	gamelist()
elseif (DO_APPGNURC)
	fixup_apprc()
else()
	license2rtf()
	cave_sprite_func()
	cave_tile_func()
	neo_sprite_func()
	psikyo_tile_func()
	toa_gp9001_func()
endif()
