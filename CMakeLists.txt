# Copyright: (C) 2017 Silvio Traversaro
# Authors: Silvio Traversaro
# CopyPolicy: Released under the terms of the MIT license, see LICENSE

cmake_minimum_required(VERSION 3.5)
project(vcpkg-binary-installer-generator NONE)
# The prefix used for all the binary installer generator specific variables will be VCPKG_BIG

# Find vcpkg root directory
# TODO(traversaro): add configurability 
if(NOT VCPKG_ROOT)
  message(FATAL_ERROR "VCPKG_ROOT CMake variable not defined, please define it to point to the vcpkg root directory.")    
endif()

if(NOT VCPKG_BIG_PORTS)
  message(FATAL_ERROR "VCPKG_BIG_PORTS CMake variable not defined, please define it to the lists of the ports to include in the generated installer.")    
endif()

if(NOT VCPKG_BIG_TRIPLET)
  message(FATAL_ERROR "VCPKG_BIG_TRIPLET CMake variable not defined, please define it vcpkg triplet to use.")    
endif()

# "Install" in CMake sense the requested ports 
foreach(port IN VCPKG_BIG_PORTS)
  install(DIRECTORY ${VCPKG_ROOT}/packages/${port}_${VCPKG_BIG_TRIPLET}
          DESTINATION ${CMAKE_INSTALL_PREFIX}
          COMPONENT ${port})
endforeach()

# Configure CPack 
set(CPACK_PACKAGE_NAME "vcpkg-binary-installer")
set(CPACK_PACKAGE_VENDOR "iCub Facility, Istituto Italiano di Tecnologia (IIT)")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Installer for ")

set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "0")
set(CPACK_PACKAGE_VERSION_PATCH "1")
set(CPACK_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

if(WIN32 AND CMAKE_GENERATOR MATCHES "^Visual Studio")
  if(MSVC10)
    set(CPACK_SYSTEM_NAME v10)
  elseif(MSVC11)
    set(CPACK_SYSTEM_NAME v11)
  elseif(MSVC12)
    set(CPACK_SYSTEM_NAME v12)
  elseif(MSVC14)
    set(CPACK_SYSTEM_NAME v14)
  endif()

  if(CMAKE_GENERATOR_PLATFORM MATCHES "x64" OR CMAKE_GENERATOR MATCHES "Win64")
    string(APPEND CPACK_SYSTEM_NAME _x86_amd64)
    set(CPACK_NSIS_INSTALL_ROOT "\\$PROGRAMFILES64\\\\vcpkg-binary-installer")
  elseif(NOT CMAKE_GENERATOR MATCHES "ARM")
    string(APPEND CPACK_SYSTEM_NAME _x86)
    set(CPACK_NSIS_INSTALL_ROOT "\\$PROGRAMFILES32\\\\vcpkg-binary-installer")
  endif()
endif()
include(CPack)
