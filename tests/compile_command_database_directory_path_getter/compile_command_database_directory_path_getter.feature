Feature: Path to compilation database is retrieved

    Scenario: The root directory is returned, if no config file is provided, and compilation database exist in root

        Given Compilation database under path "."
        When Compilation database path is obtained for file "some_dir/some_file.cpp"
        Then The root directory is returned

    Scenario: Error is raised when no config file and no compilation database is provided in root directory

        When Compilation database path is obtained for file "some_file.cpp"
        Then Error is raised

    Scenario: Error is raised when config file is provided but no path matches

        Given Config file
        """
        compile_db:
            - build/:
                - .*/makapaka.cpp
        """
        When Compilation database path is obtained for file "yolo.cpp"
        Then Error is raised

    Scenario: Basic subdirectory match

        Given Config file
        """
        compile_db:
            - build_host/:
                - Application/Source/logic/.*
                - tests/host/.*
            - build_device/:
                - .*
        """
        When Compilation database path is obtained for file "tests/host/basta.cpp"
        Then Compilation database directory "build_host/" is returned

    Scenario: Regex match for multiple compilation database directories

        Given Config file
        """
        compile_db:
            - build_one/:
                - Application/Source/logic/.*
                - tests/host/.*
            - build_two/:
                - some/dir/yolo/.*
                - some/dir1/yolo/.*
                - some/dir2/yolo/.*
            - build_three/:
                - .*
        """
        When Compilation database path is obtained for file "some/dir1/yolo/bambo/rambo/shambo.hpp"
        Then Compilation database directory "build_two/" is returned


    Scenario: Default match points to the root directory

        Given Config file
        """
        compile_db:
            - build_one/:
                - Application/Source/logic/.*
                - tests/host/.*
            - build_two/:
                - some/dir/yolo/.*
                - some/dir2/yolo/.*
            - .:
                - .*
        """
        When Compilation database path is obtained for file "some/other/file/in/shambo.hpp"
        Then Compilation database directory "." is returned

    Scenario: Default match points to a nested directory

        Given Config file
        """
        compile_db:
            - build_one/:
                - Application/Source/logic/.*
                - tests/host/.*
            - build_two/:
                - some/dir/yolo/.*
                - some/dir2/yolo/.*
            - build_three:
                - .*
        """
        When Compilation database path is obtained for file "some/other/file/in/shambo.hpp"
        Then Compilation database directory "build_three" is returned

