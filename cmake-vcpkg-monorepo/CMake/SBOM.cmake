cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

# Guard against multiple inclusions
if(COMMAND sbom_generate)
    return()
endif()

# ==============================================================================
# SBOM Generation for SPDX-2.3 JSON format
#
# This module provides functions to generate Software Bill of Materials (SBOM)
# in SPDX-2.3 JSON format for C++ applications and libraries.
# ==============================================================================

# Global variables for SBOM state
# Use global properties to store JSON data with newlines
define_property(GLOBAL PROPERTY SBOM_PACKAGES BRIEF_DOCS "List of packages in SBOM" FULL_DOCS "List of packages in SBOM")
define_property(GLOBAL PROPERTY SBOM_FILES BRIEF_DOCS "List of files in SBOM" FULL_DOCS "List of files in SBOM")
define_property(GLOBAL PROPERTY SBOM_RELATIONSHIPS BRIEF_DOCS "List of relationships in SBOM" FULL_DOCS "List of relationships in SBOM")

# Generate ISO 8601 timestamp
function(_sbom_get_timestamp out_var)
    string(TIMESTAMP timestamp "%Y-%m-%dT%H:%M:%SZ" UTC)
    set(${out_var} "${timestamp}" PARENT_SCOPE)
endfunction()

# Generate unique SPDX ID
function(_sbom_generate_spdxid base_name out_var)
    # Replace non-alphanumeric characters with hyphens
    string(REGEX REPLACE "[^A-Za-z0-9]+" "-" clean_name "${base_name}")

    # Remove leading/trailing hyphens
    string(REGEX REPLACE "^-+|-+$" "" clean_name "${clean_name}")
    set(${out_var} "SPDXRef-${clean_name}" PARENT_SCOPE)
endfunction()

# Calculate file checksums
function(_sbom_calculate_checksums file_path out_sha1 out_sha256)
    if(EXISTS "${file_path}")
        file(SHA1 "${file_path}" sha1_hash)
        file(SHA256 "${file_path}" sha256_hash)
        set(${out_sha1} "${sha1_hash}" PARENT_SCOPE)
        set(${out_sha256} "${sha256_hash}" PARENT_SCOPE)
    else()
        set(${out_sha1} "" PARENT_SCOPE)
        set(${out_sha256} "" PARENT_SCOPE)
    endif()
endfunction()

# Escape JSON string
function(_sbom_escape_json input_string out_var)
    string(REPLACE "\\" "\\\\" escaped "${input_string}")
    string(REPLACE "\"" "\\\"" escaped "${escaped}")
    string(REPLACE "\n" "\\n" escaped "${escaped}")
    string(REPLACE "\r" "\\r" escaped "${escaped}")
    string(REPLACE "\t" "\\t" escaped "${escaped}")
    set(${out_var} "${escaped}" PARENT_SCOPE)
endfunction()

# Generate JSON array from list
function(_sbom_list_to_json_array input_list out_var)
    if(NOT input_list)
        set(${out_var} "[]" PARENT_SCOPE)
        return()
    endif()

    set(json_array "[")
    set(first_item TRUE)

    foreach(item ${input_list})
        if(NOT first_item)
            string(APPEND json_array ",")
        endif()

        _sbom_escape_json("${item}" escaped_item)
        string(APPEND json_array "\n      \"${escaped_item}\"")
        set(first_item FALSE)
    endforeach()

    string(APPEND json_array "\n    ]")
    set(${out_var} "${json_array}" PARENT_SCOPE)
endfunction()

# Add package to SBOM
function(sbom_add_package)
    set(oneValueArgs
        NAME VERSION DOWNLOAD_LOCATION HOMEPAGE SUPPLIER
        LICENSE_CONCLUDED LICENSE_DECLARED COPYRIGHT_TEXT
        COMMENT SUMMARY DESCRIPTION PURPOSE
    )
    set(multiValueArgs EXTERNAL_REFS)

    cmake_parse_arguments(PKG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT PKG_NAME)
        message(FATAL_ERROR "sbom_add_package: NAME is required")
    endif()

    # Generate SPDX ID
    _sbom_generate_spdxid("${PKG_NAME}" pkg_spdxid)

    # Set defaults
    if(NOT PKG_VERSION)
        set(PKG_VERSION "NOASSERTION")
    endif()

    if(NOT PKG_DOWNLOAD_LOCATION)
        set(PKG_DOWNLOAD_LOCATION "NOASSERTION")
    endif()

    if(NOT PKG_LICENSE_CONCLUDED)
        set(PKG_LICENSE_CONCLUDED "NOASSERTION")
    endif()

    if(NOT PKG_LICENSE_DECLARED)
        set(PKG_LICENSE_DECLARED "NOASSERTION")
    endif()

    if(NOT PKG_COPYRIGHT_TEXT)
        set(PKG_COPYRIGHT_TEXT "NOASSERTION")
    endif()

    # Escape JSON values
    _sbom_escape_json("${PKG_NAME}" pkg_name_json)
    _sbom_escape_json("${PKG_VERSION}" pkg_version_json)
    _sbom_escape_json("${PKG_DOWNLOAD_LOCATION}" pkg_download_json)
    _sbom_escape_json("${PKG_LICENSE_CONCLUDED}" pkg_license_concluded_json)
    _sbom_escape_json("${PKG_LICENSE_DECLARED}" pkg_license_declared_json)
    _sbom_escape_json("${PKG_COPYRIGHT_TEXT}" pkg_copyright_json)

    # Build package JSON
    set(package_json "    {
      \"SPDXID\": \"${pkg_spdxid}\",
      \"name\": \"${pkg_name_json}\",
      \"versionInfo\": \"${pkg_version_json}\",
      \"downloadLocation\": \"${pkg_download_json}\",
      \"filesAnalyzed\": false,
      \"licenseConcluded\": \"${pkg_license_concluded_json}\",
      \"licenseDeclared\": \"${pkg_license_declared_json}\",
      \"copyrightText\": \"${pkg_copyright_json}\"")

    # Add optional fields
    if(PKG_HOMEPAGE)
        _sbom_escape_json("${PKG_HOMEPAGE}" pkg_homepage_json)
        string(APPEND package_json ",\n      \"homepage\": \"${pkg_homepage_json}\"")
    endif()

    if(PKG_SUPPLIER)
        _sbom_escape_json("${PKG_SUPPLIER}" pkg_supplier_json)
        string(APPEND package_json ",\n      \"supplier\": \"${pkg_supplier_json}\"")
    endif()

    if(PKG_COMMENT)
        _sbom_escape_json("${PKG_COMMENT}" pkg_comment_json)
        string(APPEND package_json ",\n      \"comment\": \"${pkg_comment_json}\"")
    endif()

    if(PKG_SUMMARY)
        _sbom_escape_json("${PKG_SUMMARY}" pkg_summary_json)
        string(APPEND package_json ",\n      \"summary\": \"${pkg_summary_json}\"")
    endif()

    if(PKG_DESCRIPTION)
        _sbom_escape_json("${PKG_DESCRIPTION}" pkg_description_json)
        string(APPEND package_json ",\n      \"description\": \"${pkg_description_json}\"")
    endif()

    if(PKG_PURPOSE)
        string(APPEND package_json ",\n      \"primaryPackagePurpose\": \"${PKG_PURPOSE}\"")
    endif()

    # Add external references
    if(PKG_EXTERNAL_REFS)
        string(APPEND package_json ",\n      \"externalRefs\": [")
        set(first_ref TRUE)

        foreach(ref ${PKG_EXTERNAL_REFS})
            if(NOT first_ref)
                string(APPEND package_json ",")
            endif()

            string(APPEND package_json "\n        ${ref}")
            set(first_ref FALSE)
        endforeach()

        string(APPEND package_json "\n      ]")
    endif()

    string(APPEND package_json "\n    }")

    # Add to global packages list
    get_property(current_packages GLOBAL PROPERTY SBOM_PACKAGES)

    if(current_packages)
        set_property(GLOBAL PROPERTY SBOM_PACKAGES "${current_packages},\n${package_json}")
    else()
        set_property(GLOBAL PROPERTY SBOM_PACKAGES "${package_json}")
    endif()

    # Set as last SPDXID for relationships
    set(SBOM_LAST_SPDXID "${pkg_spdxid}" PARENT_SCOPE)
endfunction()

# Add file to SBOM
function(sbom_add_file file_path)
    set(oneValueArgs
        LICENSE_CONCLUDED COPYRIGHT_TEXT COMMENT
        NOTICE_TEXT
    )
    set(multiValueArgs FILE_TYPES CONTRIBUTORS ATTRIBUTION_TEXTS)

    cmake_parse_arguments(FILE_ARG "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if(NOT EXISTS "${file_path}")
        # Don't warn - this is handled by the caller now
        return()
    endif()

    # Get relative path from install prefix
    file(RELATIVE_PATH rel_path "${CMAKE_INSTALL_PREFIX}" "${file_path}")

    if(IS_ABSOLUTE "${rel_path}" OR rel_path MATCHES "^\\.\\.")
        # File is outside install prefix, use absolute path
        set(rel_path "${file_path}")
    else()
        set(rel_path "./${rel_path}")
    endif()

    # Generate SPDX ID
    get_filename_component(file_name "${file_path}" NAME)
    _sbom_generate_spdxid("file-${file_name}" file_spdxid)

    # Calculate checksums
    _sbom_calculate_checksums("${file_path}" sha1_hash sha256_hash)

    # Set defaults
    if(NOT FILE_ARG_LICENSE_CONCLUDED)
        set(FILE_ARG_LICENSE_CONCLUDED "NOASSERTION")
    endif()

    if(NOT FILE_ARG_COPYRIGHT_TEXT)
        set(FILE_ARG_COPYRIGHT_TEXT "NOASSERTION")
    endif()

    # Escape JSON values
    _sbom_escape_json("${rel_path}" file_name_json)
    _sbom_escape_json("${FILE_ARG_LICENSE_CONCLUDED}" file_license_json)
    _sbom_escape_json("${FILE_ARG_COPYRIGHT_TEXT}" file_copyright_json)

    # Build checksums array
    set(checksums_json "[\n        {\"algorithm\": \"SHA1\", \"checksumValue\": \"${sha1_hash}\"},\n        {\"algorithm\": \"SHA256\", \"checksumValue\": \"${sha256_hash}\"}\n      ]")

    # Build file JSON
    set(file_json "    {
      \"SPDXID\": \"${file_spdxid}\",
      \"fileName\": \"${file_name_json}\",
      \"checksums\": ${checksums_json},
      \"licenseConcluded\": \"${file_license_json}\",
      \"copyrightText\": \"${file_copyright_json}\"")

    # Add optional fields
    if(FILE_ARG_FILE_TYPES)
        _sbom_list_to_json_array("${FILE_ARG_FILE_TYPES}" file_types_json)
        string(APPEND file_json ",\n      \"fileTypes\": ${file_types_json}")
    endif()

    if(FILE_ARG_COMMENT)
        _sbom_escape_json("${FILE_ARG_COMMENT}" file_comment_json)
        string(APPEND file_json ",\n      \"comment\": \"${file_comment_json}\"")
    endif()

    if(FILE_ARG_NOTICE_TEXT)
        _sbom_escape_json("${FILE_ARG_NOTICE_TEXT}" file_notice_json)
        string(APPEND file_json ",\n      \"noticeText\": \"${file_notice_json}\"")
    endif()

    if(FILE_ARG_CONTRIBUTORS)
        _sbom_list_to_json_array("${FILE_ARG_CONTRIBUTORS}" contributors_json)
        string(APPEND file_json ",\n      \"fileContributors\": ${contributors_json}")
    endif()

    if(FILE_ARG_ATTRIBUTION_TEXTS)
        _sbom_list_to_json_array("${FILE_ARG_ATTRIBUTION_TEXTS}" attribution_json)
        string(APPEND file_json ",\n      \"attributionTexts\": ${attribution_json}")
    endif()

    string(APPEND file_json "\n    }")

    # Add to global files list
    get_property(current_files GLOBAL PROPERTY SBOM_FILES)

    if(current_files)
        set_property(GLOBAL PROPERTY SBOM_FILES "${current_files},\n${file_json}")
    else()
        set_property(GLOBAL PROPERTY SBOM_FILES "${file_json}")
    endif()

    # Set as last SPDXID for relationships
    set(SBOM_LAST_SPDXID "${file_spdxid}" PARENT_SCOPE)
endfunction()

# Add relationship to SBOM
function(sbom_add_relationship spdx_element_id relationship_type related_spdx_element)
    set(oneValueArgs COMMENT)
    cmake_parse_arguments(REL "" "${oneValueArgs}" "" ${ARGN})

    # Escape JSON values
    _sbom_escape_json("${spdx_element_id}" element_id_json)
    _sbom_escape_json("${relationship_type}" rel_type_json)
    _sbom_escape_json("${related_spdx_element}" related_element_json)

    # Build relationship JSON
    set(relationship_json "    {
      \"spdxElementId\": \"${element_id_json}\",
      \"relationshipType\": \"${rel_type_json}\",
      \"relatedSpdxElement\": \"${related_element_json}\"")

    if(REL_COMMENT)
        _sbom_escape_json("${REL_COMMENT}" rel_comment_json)
        string(APPEND relationship_json ",\n      \"comment\": \"${rel_comment_json}\"")
    endif()

    string(APPEND relationship_json "\n    }")

    # Add to global relationships list
    get_property(current_relationships GLOBAL PROPERTY SBOM_RELATIONSHIPS)

    if(current_relationships)
        set_property(GLOBAL PROPERTY SBOM_RELATIONSHIPS "${current_relationships},\n${relationship_json}")
    else()
        set_property(GLOBAL PROPERTY SBOM_RELATIONSHIPS "${relationship_json}")
    endif()
endfunction()

# Add target (executable or library) to SBOM
function(sbom_add_target target_name)
    # Skip generator expressions - they can't be resolved at configure time
    if("${target_name}" MATCHES "\\$<.*>")
        message(STATUS "Skipping generator expression target: ${target_name}")
        return()
    endif()

    # Skip empty target names
    if("${target_name}" STREQUAL "")
        return()
    endif()

    if(NOT TARGET ${target_name})
        # message(WARNING "sbom_add_target: Target '${target_name}' does not exist, skipping")
        return()
    endif()

    # Get target properties
    get_target_property(target_type ${target_name} TYPE)
    get_target_property(target_sources ${target_name} SOURCES)
    get_target_property(target_version ${target_name} VERSION)

    # Determine package purpose based on target type
    if(target_type STREQUAL "EXECUTABLE")
        set(package_purpose "APPLICATION")
    else()
        set(package_purpose "LIBRARY")
    endif()

    # Add package for the target
    sbom_add_package(
        NAME "${target_name}"
        VERSION "${target_version}"
        PURPOSE "${package_purpose}"
        DOWNLOAD_LOCATION "NOASSERTION"
        LICENSE_CONCLUDED "NOASSERTION"
        LICENSE_DECLARED "NOASSERTION"
        COPYRIGHT_TEXT "NOASSERTION"
        COMMENT "Generated from CMake target ${target_name}"
    )

    set(target_spdxid "${SBOM_LAST_SPDXID}")

    # Add source files
    if(target_sources)
        # Get the target's source directory for resolving relative paths
        get_target_property(target_source_dir ${target_name} SOURCE_DIR)

        if(NOT target_source_dir)
            set(target_source_dir "${CMAKE_CURRENT_SOURCE_DIR}")
        endif()

        foreach(source_file ${target_sources})
            # Make path absolute
            if(NOT IS_ABSOLUTE "${source_file}")
                set(abs_source_file "${target_source_dir}/${source_file}")
            else()
                set(abs_source_file "${source_file}")
            endif()

            # Skip files that don't exist (they might be generated at build time)
            if(NOT EXISTS "${abs_source_file}")
                message(STATUS "Skipping non-existent source file: ${source_file}")
                continue()
            endif()

            # Determine file type based on extension
            get_filename_component(file_ext "${abs_source_file}" LAST_EXT)

            if(file_ext MATCHES "\\.(cpp|cxx|cc|c)$")
                set(file_types "SOURCE")
            elseif(file_ext MATCHES "\\.(h|hpp|hxx)$")
                set(file_types "SOURCE")
            else()
                set(file_types "OTHER")
            endif()

            sbom_add_file("${abs_source_file}"
                FILE_TYPES "${file_types}"
                LICENSE_CONCLUDED "NOASSERTION"
                COPYRIGHT_TEXT "NOASSERTION"
            )

            # Add CONTAINS relationship if file was successfully added
            if(SBOM_LAST_SPDXID)
                sbom_add_relationship("${target_spdxid}" "CONTAINS" "${SBOM_LAST_SPDXID}")
            endif()
        endforeach()
    endif()

    set(SBOM_LAST_SPDXID "${target_spdxid}" PARENT_SCOPE)
endfunction()

# Main SBOM generation function
function(sbom_generate)
    set(oneValueArgs
        OUTPUT_FILE
        DOCUMENT_NAME
        DOCUMENT_NAMESPACE
        PACKAGE_NAME
        PACKAGE_VERSION
        PACKAGE_DOWNLOAD_LOCATION
        PACKAGE_HOMEPAGE
        PACKAGE_SUPPLIER
        PACKAGE_LICENSE_CONCLUDED
        PACKAGE_LICENSE_DECLARED
        PACKAGE_COPYRIGHT
        PACKAGE_COMMENT
        PACKAGE_SUMMARY
        PACKAGE_DESCRIPTION
        PACKAGE_PURPOSE
    )
    set(multiValueArgs
        CREATORS
        PACKAGE_EXTERNAL_REFS
        TARGETS
        FILES
    )

    cmake_parse_arguments(SBOM "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate required arguments
    if(NOT SBOM_OUTPUT_FILE)
        message(FATAL_ERROR "sbom_generate: OUTPUT_FILE is required")
    endif()

    if(NOT SBOM_DOCUMENT_NAME)
        set(SBOM_DOCUMENT_NAME "${PROJECT_NAME}-SBOM")
    endif()

    if(NOT SBOM_DOCUMENT_NAMESPACE)
        message(FATAL_ERROR "sbom_generate: DOCUMENT_NAMESPACE is required")
    endif()

    if(NOT SBOM_PACKAGE_NAME)
        set(SBOM_PACKAGE_NAME "${PROJECT_NAME}")
    endif()

    if(NOT SBOM_CREATORS)
        set(SBOM_CREATORS "Tool: CMake-${CMAKE_VERSION}")
    endif()

    # Clear previous SBOM data
    set_property(GLOBAL PROPERTY SBOM_PACKAGES "")
    set_property(GLOBAL PROPERTY SBOM_FILES "")
    set_property(GLOBAL PROPERTY SBOM_RELATIONSHIPS "")

    # Generate timestamp
    _sbom_get_timestamp(creation_time)

    # Generate main package SPDX ID
    _sbom_generate_spdxid("${SBOM_PACKAGE_NAME}" main_package_spdxid)

    # Set defaults for main package
    if(NOT SBOM_PACKAGE_VERSION)
        set(SBOM_PACKAGE_VERSION "${PROJECT_VERSION}")

        if(NOT SBOM_PACKAGE_VERSION)
            set(SBOM_PACKAGE_VERSION "NOASSERTION")
        endif()
    endif()

    if(NOT SBOM_PACKAGE_DOWNLOAD_LOCATION)
        set(SBOM_PACKAGE_DOWNLOAD_LOCATION "NOASSERTION")
    endif()

    if(NOT SBOM_PACKAGE_LICENSE_CONCLUDED)
        set(SBOM_PACKAGE_LICENSE_CONCLUDED "NOASSERTION")
    endif()

    if(NOT SBOM_PACKAGE_LICENSE_DECLARED)
        set(SBOM_PACKAGE_LICENSE_DECLARED "NOASSERTION")
    endif()

    if(NOT SBOM_PACKAGE_COPYRIGHT)
        set(SBOM_PACKAGE_COPYRIGHT "NOASSERTION")
    endif()

    # Add main package
    sbom_add_package(
        NAME "${SBOM_PACKAGE_NAME}"
        VERSION "${SBOM_PACKAGE_VERSION}"
        DOWNLOAD_LOCATION "${SBOM_PACKAGE_DOWNLOAD_LOCATION}"
        HOMEPAGE "${SBOM_PACKAGE_HOMEPAGE}"
        SUPPLIER "${SBOM_PACKAGE_SUPPLIER}"
        LICENSE_CONCLUDED "${SBOM_PACKAGE_LICENSE_CONCLUDED}"
        LICENSE_DECLARED "${SBOM_PACKAGE_LICENSE_DECLARED}"
        COPYRIGHT_TEXT "${SBOM_PACKAGE_COPYRIGHT}"
        COMMENT "${SBOM_PACKAGE_COMMENT}"
        SUMMARY "${SBOM_PACKAGE_SUMMARY}"
        DESCRIPTION "${SBOM_PACKAGE_DESCRIPTION}"
        PURPOSE "${SBOM_PACKAGE_PURPOSE}"
        EXTERNAL_REFS "${SBOM_PACKAGE_EXTERNAL_REFS}"
    )

    # Add targets
    if(SBOM_TARGETS)
        foreach(target ${SBOM_TARGETS})
            # Skip generator expressions and empty strings
            if(NOT "${target}" MATCHES "\\$<.*>" AND NOT "${target}" STREQUAL "")
                sbom_add_target("${target}")
            endif()
        endforeach()
    endif()

    # Add individual files
    if(SBOM_FILES)
        foreach(file ${SBOM_FILES})
            sbom_add_file("${file}")
        endforeach()
    endif()

    # Build creators array
    _sbom_list_to_json_array("${SBOM_CREATORS}" creators_json)

    # Escape JSON values for document
    _sbom_escape_json("${SBOM_DOCUMENT_NAME}" doc_name_json)
    _sbom_escape_json("${SBOM_DOCUMENT_NAMESPACE}" doc_namespace_json)

    # Get component data
    get_property(packages_content GLOBAL PROPERTY SBOM_PACKAGES)
    get_property(files_content GLOBAL PROPERTY SBOM_FILES)
    get_property(relationships_content GLOBAL PROPERTY SBOM_RELATIONSHIPS)

    # Ensure arrays are not empty
    if(NOT packages_content)
        set(packages_content "")
    endif()

    if(NOT files_content)
        set(files_content "")
    endif()

    if(NOT relationships_content)
        set(relationships_content "")
    endif()

    # Generate complete SPDX JSON
    set(spdx_json "{
  \"spdxVersion\": \"SPDX-2.3\",
  \"dataLicense\": \"CC0-1.0\",
  \"SPDXID\": \"SPDXRef-DOCUMENT\",
  \"name\": \"${doc_name_json}\",
  \"documentNamespace\": \"${doc_namespace_json}\",
  \"creationInfo\": {
    \"creators\": ${creators_json},
    \"created\": \"${creation_time}\"
  },
  \"documentDescribes\": [
    \"${main_package_spdxid}\"
  ]")

    # Add packages section
    if(packages_content)
        string(APPEND spdx_json ",\n  \"packages\": [\n${packages_content}\n  ]")
    endif()

    # Add files section
    if(files_content)
        string(APPEND spdx_json ",\n  \"files\": [\n${files_content}\n  ]")
    endif()

    # Add relationships section
    if(relationships_content)
        string(APPEND spdx_json ",\n  \"relationships\": [\n${relationships_content}\n  ]")
    endif()

    string(APPEND spdx_json "\n}")

    # Write SBOM file
    file(WRITE "${SBOM_OUTPUT_FILE}" "${spdx_json}")

    message(STATUS "SBOM generated: ${SBOM_OUTPUT_FILE}")
endfunction()
