# do the automoc handling 

# Copyright (c) 2006, Alexander Neundorf, <neundorf@kde.org>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

include(${KDE4_AUTOMOC_FILE})

macro(PARSE_ONE_FILE _filename _moc_mark_FILE)
   if ("${_filename}" IS_NEWER_THAN "${_moc_mark_FILE}")
      file(WRITE "${_moc_mark_FILE}" "#file is autogenerated, do not edit\n")

      file(READ "${_filename}" _contents)

      get_filename_component(_abs_PATH "${_filename}" PATH)
      message(STATUS "Automoc: Parsing ${_filename}")

      set(_mocs_PER_FILE)

      string(REGEX MATCHALL "#include +([\"<]moc_[^ ]+\\.cpp|[^ ]+\\.moc)[\">]" _match "${_contents}")
      if (_match)
         foreach (_current_MOC_INC ${_match})
            string(REGEX MATCH "[^ <\"]+\\.moc" _current_MOC "${_current_MOC_INC}")
            if(_current_MOC)
               get_filename_component(_basename ${_current_MOC} NAME_WE)
            else(_current_MOC)
               string(REGEX MATCH "moc_[^ <\"]+\\.cpp" _current_MOC "${_current_MOC_INC}")
               get_filename_component(_basename ${_current_MOC} NAME_WE)
               string(REPLACE "moc_" "" _basename "${_basename}")
            endif(_current_MOC)

            set(_header ${_abs_PATH}/${_basename}.h)
            set(_moc    ${KDE4_CURRENT_BINARY_DIR}/${_current_MOC})

            if (NOT EXISTS ${_header})
               message(FATAL_ERROR "In the file \"${_filename}\" the moc file \"${_current_MOC}\" is included, but \"${_header}\" doesn't exist.")
            endif (NOT EXISTS ${_header})

            list(APPEND _mocs_PER_FILE ${_basename})
            file(APPEND ${_moc_mark_FILE} "set( ${_basename}_MOC ${_moc})\n")
            file(APPEND ${_moc_mark_FILE} "set( ${_basename}_HEADER ${_header})\n")
         endforeach (_current_MOC_INC)
      endif (_match)
      file(APPEND ${_moc_mark_FILE} "set(mocs ${_mocs_PER_FILE})\n")
   endif ("${_filename}" IS_NEWER_THAN "${_moc_mark_FILE}")

endmacro(PARSE_ONE_FILE)

foreach( _current_FILE ${MOC_FILES})
#   message(STATUS "Automoc: Checking ${_current_FILE}...")

   get_filename_component(_basename ${_current_FILE} NAME)
   set(_moc_mark_FILE ${CMAKE_CURRENT_BINARY_DIR}/${_basename}_automoc.mark)

   if(EXISTS ${_moc_mark_FILE})
      set(_force_MOC FALSE)
   else(EXISTS ${_moc_mark_FILE})
      set(_force_MOC TRUE)
   endif(EXISTS ${_moc_mark_FILE})

   parse_one_file(${_current_FILE} ${_moc_mark_FILE})
   
   include(${_moc_mark_FILE})
   
   foreach(_current_MOC ${mocs})
      if ("${${_current_MOC}_HEADER}" IS_NEWER_THAN "${${_current_MOC}_MOC}" OR _force_MOC)
         message(STATUS "Automoc: Generating ${${_current_MOC}_MOC} from ${${_current_MOC}_HEADER}")
         execute_process(COMMAND ${QT_MOC_EXECUTABLE} ${QT_MOC_INCS} ${${_current_MOC}_HEADER} -o ${${_current_MOC}_MOC})
         
      endif ("${${_current_MOC}_HEADER}" IS_NEWER_THAN "${${_current_MOC}_MOC}" OR _force_MOC)
   endforeach(_current_MOC)


endforeach( _current_FILE)

