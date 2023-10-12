#!/usr/bin/env python3
import sys
import subprocess


def build():
    print("Generating build files ...")
    run(
        "cmake -S external/Tsepepe -B build -DCMAKE_INSTALL_PREFIX=output/"
        " -DCMAKE_BUILD_TYPE=Release"
    )
    print("Building ...")
    run("cmake --build build/")
    print("Installing ...")
    run("cmake --install build/")


def run(command: str):
    cmd = command.split(" ")
    cmd_result = subprocess.run(cmd, capture_output=True)
    if cmd_result.returncode != 0:
        eprint("Failed executing command: {}".format(command))
        print(cmd_result.stdout)
        eprint(cmd_result.stderr)
        exit(cmd_result.returncode)


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


if __name__ == "__main__":
    build()
