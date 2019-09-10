# vcpkg-cpack

Generator of binary installers using [CPack](https://cmake.org/cmake/help/v3.12/module/CPack.html) for libraries built by [vcpkg](https://github.com/Microsoft/vcpkg),  alpha version, may still contain bugs. 

Note that it is possible to created binary installer using the [export option](https://docs.microsoft.com/en-us/cpp/vcpkg#export_binaries_per_project) of vcpkg, but using CPack 
gives more freedom in customizing the installer, such as adding pre and post install scripts. 

## Usage
This repo contains a CMake project that downloads an internal copy of `vcpkg`, that be configured to generated arbitrary installers.  

In particular one can set the following CMake variables to customize the behaviour of the generated installer. 

The following variables are vcpkg-cpack specific: 

| CMake variable | Description         |  Default (if any) | 
|:--------------:|:-------------------:|:-------------------:|
| `VCPKG_GIT_REPOSITORY` | vcpkg git repository. | https://github.com/Microsoft/vcpkg.git | 
| `VCPKG_GIT_TAG`        | vcpkg tag/commit to use. | `2019.08` | 
| `VCPKG_ADDITIONAL_OPTIONS` | Additional command line options passed to each vcpkg invocation (useful to specify [ports overlay](https://github.com/microsoft/vcpkg/blob/master/docs/specifications/ports-overlay.md) ) | | 
| `VCPKG_CPACK_TARGET_PORTS` | CMake list (;-separated string) of vcpkg ports to include in the installer. | |
| `VCPKG_CPACK_TARGET_TRIPLETS` |  CMake list (;-separated string) of vcpkg triplets to include in the installer. | |
| `VCPKG_CPACK_IFW_CREATE_ONLINE_INSTALLER` | If using the IFW generator, create an online installer (note: experimental option). | `OFF` |

The other variables are common CPack variables, including:
 
| CMake variable | Default (if any) | 
|:--------------:|:--------------:|
| `CPACK_PACKAGE_NAME` | vcpkg-cpack-generated-installer |
| `CPACK_PACKAGE_VENDOR` | vcpkg-cpack Vendor | 
| `CPACK_PACKAGE_DESCRIPTION_SUMMARY` | vcpkg-cpack Description Summary |
| `CPACK_PACKAGE_VERSION_MAJOR` |  |
| `CPACK_PACKAGE_VERSION_MINOR` |  |
| `CPACK_PACKAGE_VERSION_PATCH` |  |
| `CPACK_GENERATOR` | IFW;ZIP | 

For a complete list and description of CPack options, check https://cmake.org/cmake/help/v3.5/module/CPack.html . 
Note that at the moment only the `IFW` and `ZIP` have been tested. 

For reproducibility, it is often convenient to store all this option in a [initial cache CMake file](https://cgold.readthedocs.io/en/latest/tutorials/variables/cache.html#initial-cache)
and pass to CMake using the -C option. An example of this is the [`examples/robotology-additional-dependencies-64.cmake`](examples/robotology-additional-dependencies-64.cmake), 
that is used to generate the robotology-additional-dependencies installers, that are available at https://github.com/robotology-playground/robotology-additional-dependencies . 

## Enviroment variables handling 
When installing a set of libraries, it is often convenient to give the user the option to automatically 
modify its own [user enviroment variables](https://www.thewindowsclub.com/system-user-environment-variables-windows). 
`vcpkg-cpack` provide this support by adding to `IFW`-generated installers an `update_env_variables_${triplet_comp}` component 
that optionally modifies the `PATH` and `CMAKE_PREFIX_PATH` to find the installed libraries. Note that this may not be 
sufficient for port that installs program, such as `protobuf`. Support for more envromental variables will be added in the future. 

The changes in the enviromental variables are properly reverted during the uninstallation.
