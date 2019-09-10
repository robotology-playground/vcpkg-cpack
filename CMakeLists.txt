# Copyright: (C) 2018 Silvio Traversaro
# Copyright: (C) 2017 Daniele E. Domenichelli
# Authors: Silvio Traversaro, Daniele E. Domenichelli
# CopyPolicy: Released under the terms of the MIT license, see LICENSE

cmake_minimum_required(VERSION 3.12)
project(vcpkg_cpack NONE)

find_package(GIT)

# Download an internal copy of vcpkg using CMake's FetchContent
include(FetchContent)
set(VCPKG_GIT_REPOSITORY "https://github.com/Microsoft/vcpkg.git" CACHE STRING "vcpkg git repository to use")
set(VCPKG_GIT_TAG "2019.08" CACHE STRING "vcpkg git tag/commit to use")
FetchContent_Declare(
  vcpkg
  GIT_REPOSITORY ${VCPKG_GIT_REPOSITORY}
  GIT_TAG        ${VCPKG_GIT_TAG}
)

FetchContent_GetProperties(vcpkg)
if(NOT vcpkg_POPULATED)
  message(STATUS "Downloading internal vcpkg.")
  FetchContent_Populate(vcpkg)
    
  # Set the location of vcpkg 
  set(VCPKG_ROOT_DIR "${vcpkg_SOURCE_DIR}" CACHE STRING "Vcpkg directory" FORCE)
  set(VCPKG_EXECUTABLE "${vcpkg_SOURCE_DIR}/vcpkg.exe" CACHE STRING "Vcpkg executable" FORCE)
  
  # Bootstrap vcpkg 
  if(NOT EXISTS "${VCPKG_EXECUTABLE}")
    message(STATUS "Bootstraping internal vcpkg because ${VCPKG_EXECUTABLE} does not exist.")
    execute_process(
        COMMAND ${vcpkg_SOURCE_DIR}/bootstrap-vcpkg.bat
        WORKING_DIRECTORY ${vcpkg_SOURCE_DIR}
        OUTPUT_FILE       ${vcpkg_BINARY_DIR}/vcpkg_bootstrap_output.log
        ERROR_FILE        ${vcpkg_BINARY_DIR}/vcpkg_bootstrap_output.log
        RESULT_VARIABLE   result
    )
  else()
    message(STATUS "Internal vcpkg found, no need for bootstraping.")
  endif()
  message(STATUS "vcpkg bootstrapping complete")
endif()

# Define PACKAGES_DIR
set(TARGET_TRIPLET_FILE ${VCPKG_ROOT_DIR}/scripts/ports.cmake)
include(${VCPKG_ROOT_DIR}/scripts/ports.cmake)

unset(default_triplet)
if(DEFINED VCPKG_TARGET_TRIPLET)
  set(default_triplet ${VCPKG_TARGET_TRIPLET})
endif()
set(VCPKG_CPACK_TARGET_TRIPLETS "${default_triplet}" CACHE STRING "vcpkg triplets to support in the installer")

# User configuration 
option(VCPKG_CPACK_IFW_CREATE_ONLINE_INSTALLER OFF "If using the IFW generator, set to ON to create a online installer, OFF for an offline installer.")

set(CPACK_PACKAGE_NAME "vcpkg-cpack-generated-installer" CACHE STRING "CPack Package Name")
set(CPACK_PACKAGE_VENDOR "vcpkg-cpack Vendor" CACHE STRING "CPack Package Vendor")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "vcpkg-cpack Description Summary" CACHE STRING "CPack Package Description summary")
set(CPACK_GENERATOR "IFW;ZIP" CACHE STRING ";-separated list of CPack generators to use (currently supported generators: IFW, ZIP)")

# Process inputs 
string(REPLACE "-" "_" CPACK_PACKAGE_NAME_UNDERSCORES ${CPACK_PACKAGE_NAME})
set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

if(NOT VCPKG_CPACK_TARGET_TRIPLETS)
  message(FATAL_ERROR "No valid triplets defined")
endif()

foreach(triplet ${VCPKG_CPACK_TARGET_TRIPLETS})
  if(NOT EXISTS "${VCPKG_ROOT_DIR}/triplets/${triplet}.cmake")
    message(FATAL_ERROR "\"${triplet}\" is not a valid triplet because ${VCPKG_ROOT_DIR}/triplets/${triplet}.cmake does not exists.")
  endif()
endforeach()

if(WIN32 AND CMAKE_GENERATOR MATCHES "^Visual Studio")
  if(CMAKE_GENERATOR_PLATFORM MATCHES "x64" OR CMAKE_GENERATOR MATCHES "Win64")
    string(APPEND CPACK_SYSTEM_NAME x86_amd64)
    # FIXME: Install in "Program Files" instead of "Program Files (x86)"
  elseif(NOT CMAKE_GENERATOR MATCHES "ARM")
    string(APPEND CPACK_SYSTEM_NAME x86)
  endif()
endif()

# If not set, all components will be merged in the group
set(CPACK_COMPONENTS_GROUPING IGNORE)

set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CPACK_PACKAGE_NAME})
set(CPACK_IFW_PACKAGE_MAINTENANCE_TOOL_NAME "${CPACK_PACKAGE_NAME}-maintenancetool")
set(CPACK_IFW_PACKAGE_MAINTENANCE_TOOL_INI_FILE "${CPACK_PACKAGE_NAME}-maintenancetool.ini")
set(CPACK_IFW_PACKAGE_NAME ${CPACK_PACKAGE_DESCRIPTION_SUMMARY})
set(CPACK_IFW_PACKAGE_WIZARD_DEFAULT_WIDTH 600)
set(CPACK_IFW_PACKAGE_WIZARD_DEFAULT_HEIGHT 600)

# See https://gitlab.kitware.com/cmake/cmake/issues/16723
set(CPACK_IFW_DOWNLOAD_ALL ${VCPKG_CPACK_IFW_CREATE_ONLINE_INSTALLER})

include(CPack)
include(CPackIFW)

# Add root component
cpack_add_component_group(root
                          DISPLAY_NAME ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}
                          DESCRIPTION ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}
                          EXPANDED)
cpack_ifw_configure_component_group(root
                                    NAME org.${CPACK_PACKAGE_NAME_UNDERSCORES}.installer)
set(CPACK_IFW_PACKAGE_GROUP root)

# Parse the CONTROL file contained in packages directory (only possible when a package was already installed)
function(parse_binary_control_file port triplet)
  set(port_dir "${PACKAGES_DIR}/${port}_${triplet}")
  if(NOT IS_DIRECTORY "${port_dir}")
    message(SEND_ERROR "${port}_${triplet}: Port is not installed because ${port_dir} does not exist.")
    return()
  endif()

  set(control_file "${PACKAGES_DIR}/${port}_${triplet}/CONTROL")
  if(NOT EXISTS "${control_file}")
    message(SEND_ERROR "${port}_${triplet}: No CONTROL file found (expected ${control_file})")
    return()
  endif()

  file(STRINGS "${control_file}" control_contents)

  # Check package name
  string(REGEX REPLACE ".*Package: ([^;]+).*" "\\1" package "${control_contents}")
  if(NOT "${package}" MATCHES "${port}")
    message(SEND_ERROR "${port}_${triplet}: Package name does not match (${package})")
    return()
  endif()

  # Check architecture
  string(REGEX REPLACE ".*Architecture: ([^;]+).*" "\\1" architecture "${control_contents}")
  string(REGEX REPLACE ".*Multi-Arch: ([^;]+).*" "\\1" multiarch "${control_contents}") # FIXME use this?
  if(NOT "${architecture}" MATCHES "${triplet}")
    message(SEND_ERROR "${port}_${triplet}: Architecture name does not match (${architecture})")
    return()
  endif()

  # Detect version number
  string(REGEX REPLACE ".*Version: ([^;]+).*" "\\1" version "${control_contents}")
  string(REPLACE "-" "." version "${version}")
  string(REGEX REPLACE "[^0-9.]" "" version "${version}")

  # Detect dependencies
  if("${control_contents}" MATCHES ".*Depends: ([^;]+).*")
    string(REGEX REPLACE ".*Depends: ([^;]+).*" "\\1" depends "${control_contents}")
    string(REPLACE "," ";" depends "${depends}")
    string(REPLACE " " "" depends "${depends}")
  else()
    set(depends "")
  endif()

  # Detect description
  string(REGEX REPLACE ".*Description: ([^;]+).*" "\\1" description "${control_contents}")

  # Return variables to parent scope
  set(${port}_${triplet}_VERSION ${version} PARENT_SCOPE)
  set(${port}_${triplet}_DEPENDS ${depends} PARENT_SCOPE)
  set(${port}_${triplet}_DESCRIPTION ${description} PARENT_SCOPE)
endfunction()

# Generate a list of ports installed for at least one architecture
function(find_installed_ports var)
  unset(${var})
  foreach(triplet ${VCPKG_CPACK_TARGET_TRIPLETS})
    file(GLOB ports
         LIST_DIRECTORIES 1
         RELATIVE "${PACKAGES_DIR}"
         "${PACKAGES_DIR}/*_${triplet}")
    string(REPLACE "_${triplet}" "" ports "${ports}")

    if(NOT "${ports}" STREQUAL "")
      list(APPEND ${var} ${ports})
      list(REMOVE_DUPLICATES ${var})
    endif()
  endforeach()
  set(${var} ${${var}} PARENT_SCOPE)
endfunction()

message(STATUS "Ports explicitly selected for installation: ${VCPKG_CPACK_TARGET_PORTS}")

# First of all, install all VCPKG_CPACK_TARGET_PORTS for all the requested triplets 
foreach(triplet ${VCPKG_CPACK_TARGET_TRIPLETS})
  foreach(port ${VCPKG_CPACK_TARGET_PORTS})
    message(STATUS "Installing ${port}:${triplet}")
    execute_process(COMMAND ${VCPKG_EXECUTABLE} install ${port}:${triplet}
                    WORKING_DIRECTORY "${VCPKG_ROOT_DIR}"
                    RESULT_VARIABLE res
                    OUTPUT_QUIET
                    ERROR_QUIET)
    if(NOT res EQUAL 0)
      message(SEND_ERROR "Failed to install ${port}:${triplet}")
      continue()
    endif()
  endforeach()
endforeach()

# After vcpkg installed the ports, extract the installed ports 
find_installed_ports(installed_ports)

foreach(triplet ${VCPKG_CPACK_TARGET_TRIPLETS})
  string(REPLACE "-" "_" triplet_comp "${triplet}")
  if(NOT "${triplet}" STREQUAL "${VCPKG_CPACK_TARGET_TRIPLETS}")
    set(group ${triplet_comp})
    cpack_add_component_group(${triplet_comp}
                              DISPLAY_NAME ${triplet}
                              DESCRIPTION "${triplet} triplet"
                              PARENT_GROUP root)
    cpack_ifw_configure_component_group(${triplet_comp}
                                        NAME org.${CPACK_PACKAGE_NAME_UNDERSCORES}.installer.${triplet_comp})
  else()
    set(group root)
  endif()

  foreach(port ${installed_ports})
    parse_binary_control_file(${port} ${triplet})

    # Ensure that the package is identical for all the triplets
    foreach(var VERSION
                DEPENDS
                DESCRIPTION)
      if(DEFINED ${port}_${var})
        if(NOT "${${port}_${triplet}_${var}}" STREQUAL "${${port}_${var}}")
          message(SEND_ERROR "Port ${port} is not identical for all architectures")
          continue()
        endif()
      else()
        set(${port}_${var} ${${port}_${triplet}_${var}})
      endif()
    endforeach()

    string(REPLACE "-" "_" component ${port})
    unset(depends)
    foreach(dep ${${port}_DEPENDS})
      string(REPLACE "-" "_" dep "${dep}")
      list(APPEND depends ${dep}_${triplet_comp})
    endforeach()
    set(description "${${port}_DESCRIPTION}")

    # If available, get the release date from the latest git commit
    string(TIMESTAMP date "%Y-%m-%d")
    if(GIT_EXECUTABLE AND IS_DIRECTORY "${VCPKG_ROOT_DIR}/.git")
      execute_process(COMMAND ${GIT_EXECUTABLE} log -1 --format=%cd --date=short ports/${port}
                      WORKING_DIRECTORY "${VCPKG_ROOT_DIR}"
                      RESULT_VARIABLE res
                      OUTPUT_VARIABLE out
                      ERROR_QUIET
                      OUTPUT_STRIP_TRAILING_WHITESPACE)
      if(res EQUAL 0)
        set(date ${out})
      endif()
    endif()

    # "Install" in CMake sense the requested ports
    file(GLOB items
         LIST_DIRECTORIES 1
         "${PACKAGES_DIR}/${port}_${triplet}/*")
    unset(dirs)
    unset(files)
    foreach(item ${items})
      if(IS_DIRECTORY "${item}" )
        list(APPEND dirs "${item}" )
      elseif(NOT "${item}" MATCHES "/(BUILD_INFO|CONTROL)$")
        list(APPEND files "${item}" )
      endif()
    endforeach()
    install(FILES ${files}
            DESTINATION ${triplet}
            COMPONENT ${component}_${triplet_comp})
    install(DIRECTORY ${dirs}
            DESTINATION ${triplet}
            COMPONENT ${component}_${triplet_comp})
    configure_file("${PACKAGES_DIR}/${port}_${triplet}/share/${port}/copyright"
                   "${CMAKE_BINARY_DIR}/Licenses/${port}-${triplet}"
                   COPYONLY)

    # Hide dependencies from the installer unless explicitly selected
    option(VCPKG_CPACK_DEPENDENCIES_HIDDEN OFF "Hide dependencies components")
    unset(hidden)
    list(FIND VCPKG_CPACK_TARGET_PORTS ${port} res)
    if(res EQUAL -1 AND VCPKG_CPACK_DEPENDENCIES_HIDDEN)
      set(hidden HIDDEN)
    endif()

    # Add a CPack component
	set(component_options "")
	if(VCPKG_CPACK_IFW_CREATE_ONLINE_INSTALLER)
	  list(APPEND _component_options DOWNLOADED)
	  list(APPEND _component_options DISABLED)
	endif()
    cpack_add_component(${component}_${triplet_comp}
                        DISPLAY_NAME ${port}
                        DESCRIPTION "${description}"
                        GROUP ${group}
                        DEPENDS ${depends}
                        ${component_options}
                        ${hidden})
    cpack_ifw_configure_component(${component}_${triplet_comp}
                                  NAME org.${CPACK_PACKAGE_NAME_UNDERSCORES}.installer.${triplet_comp}.${component}
                                  VERSION ${version}
                                  RELEASE_DATE ${date}
                                  LICENSES ${port}-${triplet} "${CMAKE_BINARY_DIR}/Licenses/${port}-${triplet}")
  endforeach()
  
  # Add cpack generator-indipendent script to add the necessary env variables and remove them 
  install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/addPathsToEnvVariables.ps1 
                ${CMAKE_CURRENT_SOURCE_DIR}/removePathsFromEnvVariables.ps1
          DESTINATION ${triplet}
          COMPONENT update_env_variables_${triplet_comp})
  
  # Create custom component to manage enviromental variables for each triplet 
  cpack_add_component(update_env_variables_${triplet_comp}
                      DISPLAY_NAME "Update Enviromental Variables for ${triplet_comp}"
                      DESCRIPTION  "Update Enviromental Variables to automatically use the installed software for triplet ${triplet_comp}."
                      GROUP ${group})
  
  # Note: @TargetDir@ is actually a IFW macro, and should not be substitued by configure_file 
  # As a workaround, we define the TargetDir cmake variable as "@TargetDir@", so in  the file @TargetDir@ will be substitued by @TargetDir@
  set(TargetDir "@TargetDir@")  
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/update-env-variables.qs.in ${CMAKE_CURRENT_BINARY_DIR}/update-env-variables-${triplet_comp}.qs @ONLY)
  cpack_ifw_configure_component(update_env_variables_${triplet_comp}
                                NAME org.${CPACK_PACKAGE_NAME_UNDERSCORES}.installer.${triplet_comp}.update_env_variables
                                VERSION ${CPACK_PACKAGE_VERSION}
                                SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/update-env-variables-${triplet_comp}.qs)

endforeach()

# Configure the repository
if (VCPKG_CPACK_IFW_CREATE_ONLINE_INSTALLER)
  cpack_ifw_add_repository(${CPACK_PACKAGE_NAME}-repository
                           # URL FIXME insert the real URL
                           URL "file:///${CMAKE_BINARY_DIR}/_CPack_Packages/${CPACK_SYSTEM_NAME}/IFW/${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_SYSTEM_NAME}/repository"
                           DISPLAY_NAME  ${CPACK_PACKAGE_DESCRIPTION_SUMMARY})
endif()
