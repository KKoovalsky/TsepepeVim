import os
import sys
import importlib
from pathlib import Path
from hamcrest import assert_that, equal_to

sys.path.append("../python3")
from pytsepepevim import comp_db_dir_getter


def _assert_has_result(context):
    assert_that(hasattr(context, "result"), "No result captured!")
    assert_that(
        not hasattr(context, "error"), "Error caught, when none expected!"
    )


@given('Compilation database under path "{path}"')
def step_impl(context, path: str):
    final_path = os.path.join(
        context.working_directory, path, "compile_commands.json"
    )
    Path(final_path).touch()


@given("Config file")
def step_impl(context):
    content = context.text
    config_file_path = os.path.join(context.working_directory, ".tsepepe.yml")
    with open(config_file_path, "w") as f:
        f.write(content)


@when('Compilation database path is obtained for file "{}"')
def step_impl(context, file: str):
    importlib.reload(comp_db_dir_getter)
    project_root = context.working_directory
    file_abs_path = os.path.join(context.working_directory, file)
    try:
        result = comp_db_dir_getter.get_compile_db_dir(
            project_root, file_abs_path
        )
        context.result = result
    except comp_db_dir_getter.CompDbGetterToolError as err:
        context.error = err


@then("The root directory is returned")
def step_impl(context):
    _assert_has_result(context)
    assert_that(context.result, equal_to(context.working_directory))


@then("Error is raised")
def step_impl(context):
    assert_that(
        not hasattr(context, "result"),
        "Got result, when error should be caught!",
    )
    assert_that(hasattr(context, "error"), "No error captured!")


@then('Compilation database directory "{}" is returned')
def step_impl(context, directory: str):
    _assert_has_result(context)
    expected_result = os.path.join(context.working_directory, directory)
    assert_that(context.result, equal_to(expected_result))
