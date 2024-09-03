if (NOT MACOSX AND NOT IOS)
    message(FATAL_ERROR "This script is only for MacOS X or iOS!")
endif()

message(STATUS "Apple Team   : ${APPLE_TEAM}")
message(STATUS "Apple Sign Id: ${APPLE_SIGNID}")

set(smile_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/AppDelegate.h
    ${CMAKE_CURRENT_SOURCE_DIR}/AppDelegate.m
    ${CMAKE_CURRENT_SOURCE_DIR}/main.m
    ${CMAKE_CURRENT_SOURCE_DIR}/MainViewController.m
    ${CMAKE_CURRENT_SOURCE_DIR}/ShaderTypes.h
    ${CMAKE_CURRENT_SOURCE_DIR}/static-asserts.cpp
)

if (IOS)
    set(smile_SOURCES
        ${smile_SOURCES}
        ${CMAKE_CURRENT_SOURCE_DIR}/SceneDelegate.h
        ${CMAKE_CURRENT_SOURCE_DIR}/SceneDelegate.m
    )
endif()

set(smile_SHADERS
    ${CMAKE_CURRENT_SOURCE_DIR}/Shaders.metal
)

if (MACOSX)
    set(smile_ENTITLEMENTS
        ${CMAKE_CURRENT_SOURCE_DIR}/Resources/osx/smile.entitlements
    )
    set(smile_PLISTS
        ${CMAKE_CURRENT_SOURCE_DIR}/Resources/osx/Info.plist
    )
    set(smile_STORYBOARDS
        ${CMAKE_CURRENT_SOURCE_DIR}/Resources/osx/Base.lproj/Main.storyboard
    )
else ()
    set(smile_PLISTS
        ${CMAKE_CURRENT_SOURCE_DIR}/Resources/ios/Info.plist
    )
    set(smile_STORYBOARDS
        ${CMAKE_CURRENT_SOURCE_DIR}/Resources/ios/Base.lproj/Main.storyboard
        ${CMAKE_CURRENT_SOURCE_DIR}/Resources/ios/Base.lproj/LaunchScreen.storyboard
    )
endif()

add_executable(smile MACOSX_BUNDLE
    ${smile_SOURCES}
    ${smile_SHADERS}
    ${smile_STORYBOARDS}
    ${ASSETS_DIR}
)

smile_setup_common_flags(smile)

source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} PREFIX "[sources]"
    FILES ${smile_SOURCES}
)

source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} PREFIX "[shaders]"
    FILES ${smile_SHADERS}
)

set_source_files_properties(${smile_STORYBOARDS} PROPERTIES
    MACOSX_PACKAGE_LOCATION Resources
)
set_source_files_properties(${smile_SHADERS} PROPERTIES
    LANGUAGE METAL
)
set_source_files_properties(${ASSETS_DIR} PROPERTIES
    MACOSX_PACKAGE_LOCATION Resources
)

target_include_directories(smile PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

if (MACOSX)
    target_link_libraries(smile PUBLIC
        smile-core 
        "-framework AppKit -framework Metal -framework MetalKit"
    )
else ()
    target_link_libraries(smile PUBLIC
        smile-core
        "-framework Foundation -framework UIKit -framework Metal -framework MetalKit"
    )
endif()

if (MACOSX)
    set_target_properties(smile PROPERTIES
        XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS ${smile_ENTITLEMENTS}
        XCODE_ATTRIBUTE_LD_RUNPATH_SEARCH_PATHS "@executable_path/../Frameworks"
    )
endif()

set_target_properties(smile PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST ${smile_PLISTS}
    RESOURCE "${smile_STORYBOARDS} ${ASSETS_DIR}"

    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER ${OSX_BUNDLE}

    XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic"
    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${APPLE_TEAM}"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${APPLE_SIGNID}"

    XCODE_ATTRIBUTE_MTL_HEADER_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}"

    XCODE_ATTRIBUTE_MTL_ENABLE_DEBUG_INFO[variant=Debug]          "INCLUDE_SOURCE"
    XCODE_ATTRIBUTE_MTL_ENABLE_DEBUG_INFO[variant=MinSizeRel]     "NO"
    XCODE_ATTRIBUTE_MTL_ENABLE_DEBUG_INFO[variant=RelWithDebInfo] "INCLUDE_SOURCE"
    XCODE_ATTRIBUTE_MTL_ENABLE_DEBUG_INFO[variant=Release]        "NO"
)

