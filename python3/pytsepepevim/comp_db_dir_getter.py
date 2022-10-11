import os
import re
import yaml


_records = None


class CompDbGetterError(Exception):
    pass


class CompDbGetterToolError(Exception):
    pass


class CompDbGetterValueError(CompDbGetterError):
    pass


class _Record:
    def __init__(self, file_pattern: str, compile_db_dir: str):
        self.file_pattern = file_pattern
        self.compile_db_dir = compile_db_dir


def get_compile_db_dir(project_root: str, file: str):
    _lazy_load_config_if_exists(project_root)
    _validate_path_absolute("project root", project_root)
    _validate_path_absolute("C++ file", file)
    return _resolve_compilation_database_dir(project_root, file)


def _lazy_load_config_if_exists(project_root: str):
    config_file = os.path.join(project_root, ".tsepepe.yml")
    if not os.path.exists(config_file):
        return

    global _records
    if _records is not None:
        return

    _records = list()

    with open(config_file) as f:
        config = yaml.safe_load(f)
    try:
        mappings = config["compile_db"]
    except KeyError:
        raise CompDbGetterValueError(
            '"compile_db" key not found in {}'.format(config_file)
        )

    _validate_mappings_format(mappings, config_file)
    for mapping in mappings:
        _validate_single_mapping(mapping, config_file)
        compile_db_dir = list(mapping.keys())[0]
        for pattern in mapping[compile_db_dir]:
            _records.append(_Record(pattern, compile_db_dir))


def _validate_mappings_format(field, config_file: str):
    if not isinstance(field, list):
        raise CompDbGetterValueError(
            'The "compile_db" entity, in {}, must contain a list of objects!'
            .format(config_file)
        )


def _validate_single_mapping(field, config_file: str):
    if len(field.keys()) != 1:
        raise CompDbGetterValueError(
            (
                'The "compile_db" entity, in {}, must be a list (it is), but'
                " with single objects!"
            ).format(config_file)
        )
    k = list(field.keys())[0]
    v = field[k]
    if not isinstance(v, list) or not all([isinstance(e, str) for e in v]):
        raise CompDbGetterValueError(
            (
                'The "compile_db" entity, in {}, must be a list (it is), with'
                " single objects (it is), but mapping a key to list of strings!"
            ).format(config_file)
        )


def _validate_path_absolute(name: str, path: str):
    if not os.path.isabs(path):
        raise CompDbGetterValueError(
            "Path to: {} must be absolute, got: {}!".format(name, path)
        )


def _resolve_compilation_database_dir(project_root: str, file: str):
    rel_path = _get_relative_dir_to_project_root_or_raise_if_not_nested(
        project_root, file
    )

    if _has_user_specified_mapping():
        compile_db_dir_matched = _find_matching_pattern(rel_path)
        if compile_db_dir_matched is not None:
            return os.path.join(project_root, compile_db_dir_matched)

    # Most likely this branch will be reached, because most users will have
    # a single compilation database for the entire project, and no custom
    # .tsepepe.yml mapping will be provided.
    if _exists_compilation_database_in_root(project_root):
        return project_root

    global _records
    if _records is None:
        raise CompDbGetterToolError(
            "No compilation database found in the root directory, and no config"
            " file found, where compilation database path could be specified!"
        )
    else:
        raise CompDbGetterToolError(
            "No compilation database found in the root directory, and config"
            " file contains no matching pattern!"
        )


def _get_relative_dir_to_project_root_or_raise_if_not_nested(
    project_root: str, file: str
):
    r = os.path.relpath(file, project_root)
    if r.startswith(".."):
        raise CompDbGetterValueError(
            "File {} is not within the directory: {}!".format(
                file, project_root
            )
        )
    return r


def _has_user_specified_mapping():
    return _records is not None


def _find_matching_pattern(rel_path: str):
    global _records
    for record in _records:
        if re.match(record.file_pattern, rel_path):
            return record.compile_db_dir
    return None


def _exists_compilation_database_in_root(project_root: str):
    return os.path.exists(os.path.join(project_root, "compile_commands.json"))
