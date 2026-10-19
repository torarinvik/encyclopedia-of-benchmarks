#!/usr/bin/env python3
"""Build a reviewed implementation and its matching C ABI harness using portable flags."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "nim": "nim",
              "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}
FAMILIES = {"scalar": ("scalar_call", ["scalar_runner", "scalar_check"]),
            "binary_scalar": ("binary_scalar_call", ["binary_scalar_runner", "binary_scalar_check"]),
            "float64_i32": ("float64_i32_call", ["float64_i32_runner"]),
            "float64_pair": ("float64_pair_call", ["float64_pair_runner", "float64_pair_check"]),
            "float64_triple": ("float64_triple_call", ["float64_triple_runner", "float64_triple_check"]),
            "i64_triple": ("i64_triple_call", ["i64_triple_runner", "i64_triple_check"]),
            "float64_unary": ("float64_unary_call", ["float64_unary_runner", "float64_unary_check"]),
            "float64_point_array": ("float64_point_array_call",
                                    ["float64_point_array_runner", "float64_point_array_check"]),
            "i64_array_bytes_output": ("i64_array_bytes_output_call",
                                       ["i64_array_bytes_output_runner", "i64_array_bytes_output_check"]),
            "i32_array_bytes_output": ("i32_array_bytes_output_call",
                                       ["i32_array_bytes_output_runner", "i32_array_bytes_output_check"]),
            "i64_scalar_bytes_output": ("i64_scalar_bytes_output_call",
                                        ["i64_scalar_bytes_output_runner", "i64_scalar_bytes_output_check"]),
            "i64_array_scalar": ("i64_array_scalar_call",
                                 ["i64_array_scalar_runner", "i64_array_scalar_check"]),
            "i64_array_float64": ("i64_array_float64_call",
                                  ["i64_array_float64_runner", "i64_array_float64_check"]),
            "float64_slice_io": ("float64_slice_io_call",
                                 ["float64_slice_io_runner", "float64_slice_io_check"]),
            "search": ("binary_search", ["runner"]),
            "sort": ("sort_call", ["sort_runner", "sort_checker"]),
            "shortest_path": ("shortest_path_call", ["shortest_path_runner"]),
            "tree_level_order": ("tree_level_order_call",
                                 ["tree_level_order_runner", "tree_level_order_check"]),
            "tree_views": ("tree_views_call", ["tree_views_runner", "tree_views_check"]),
            "tree_symmetric": ("tree_symmetric_call",
                               ["tree_symmetric_runner", "tree_symmetric_check"]),
            "tree_scalar": ("tree_scalar_call",
                            ["tree_scalar_runner", "tree_scalar_check"]),
            "tree_range_sum": ("tree_range_sum_call",
                               ["tree_range_sum_runner", "tree_range_sum_check"]),
            "tree_rank": ("tree_rank_call", ["tree_rank_runner", "tree_rank_check"]),
            "tree_value_output": ("tree_value_output_call",
                                 ["tree_value_output_runner", "tree_value_output_check"]),
            "tree_trim": ("tree_trim_call", ["tree_trim_runner", "tree_trim_check"])}
COMPILERS = {"c": "cc", "c3": "c3c", "cpp": "c++", "elisa": "elisac", "nim": "nim",
             "odin": "odin", "rust": "rustc", "v": "v", "zig": "zig"}


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def resolve_tool(name: str) -> str:
    found = shutil.which(name)
    if found is None:
        raise ValueError(f"compiler not found: {name}; supply --compiler with its executable path")
    return str(Path(found).absolute())


def build(algorithm: str, language: str, directory: Path, *, compiler: str | None = None,
          cc: str = "cc", with_checker: bool = False, family: str = "scalar",
          extra_link_sources: tuple[Path, ...] = ()) -> dict:
    if re.fullmatch(r"[a-z0-9]+(?:_[a-z0-9]+)*", algorithm) is None:
        raise ValueError("algorithm must be a normalized catalog name")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    language_root = ROOT / language / letter
    source_name = f"{algorithm}.{EXTENSIONS[language]}"
    # Prefer the conventional first-letter layout when present, preserving
    # existing build resolution. Some source-backed packages keep a port in
    # its original language category directory; below, an explicit README link
    # can resolve that port while staying inside the language root.
    source_candidates = (language_root / source_name,
                         language_root / algorithm / source_name,
                         ROOT / language / source_name,
                         ROOT / language / algorithm / source_name)
    source = next((candidate for candidate in source_candidates if candidate.is_file()),
                  source_candidates[0])
    workload = ROOT / "benchmarks" / letter / algorithm / "workload.json"
    if not source.is_file():
        guide = workload.with_name("README.md")
        if guide.is_file():
            language_root_resolved = (ROOT / language).resolve()
            linked_sources = set()
            for raw_target in re.findall(
                    r"\]\(([^)]+)\)", guide.read_text(encoding="utf-8")):
                target = raw_target.strip()
                if target.startswith("<") and ">" in target:
                    target = target[1:target.index(">")]
                else:
                    target = target.split(maxsplit=1)[0] if target else ""
                parsed_target = urlsplit(target)
                if (not target or parsed_target.scheme or parsed_target.netloc
                        or not parsed_target.path or parsed_target.path.startswith(("/", "\\"))):
                    continue
                try:
                    linked_source = (guide.parent / unquote(parsed_target.path)).resolve()
                    linked_source.relative_to(language_root_resolved)
                except (OSError, RuntimeError, ValueError):
                    continue
                if (linked_source.is_file() and linked_source.name == source_name
                        and linked_source.suffix == f".{EXTENSIONS[language]}"):
                    linked_sources.add(linked_source)
            if len(linked_sources) > 1:
                raise ValueError(f"README links multiple {language} sources named {source_name}")
            if linked_sources:
                source = next(iter(linked_sources))
    if not source.is_file() or not workload.is_file():
        raise ValueError(f"source or workload missing for {algorithm}/{language}")
    spec = json.loads(workload.read_text(encoding="utf-8"))
    if family not in FAMILIES:
        raise ValueError(f"unknown C ABI family: {family}")
    model, family_harnesses = FAMILIES[family]
    if spec.get("measurement", {}).get("comparison_model") != model:
        raise ValueError(f"{algorithm} does not declare the {family} C ABI workload")
    function_symbol = spec.get("function_symbol", algorithm)
    if not isinstance(function_symbol, str) or re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", function_symbol) is None:
        raise ValueError("workload function_symbol must be a valid C identifier")
    directory = directory.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    compiler = resolve_tool(compiler or COMPILERS[language])
    c_compiler = resolve_tool(cc)
    artifact = directory / ("implementation.a" if language in {"c3", "nim", "rust"} else "implementation.o")
    commands: list[list[str]] = []
    native_link_flags: list[str] = []
    extra_link_objects: list[Path] = []

    def run(command: list[str]) -> subprocess.CompletedProcess:
        commands.append(command)
        completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=180)
        if completed.returncode:
            raise RuntimeError(f"{shlex.join(command)}\n{completed.stdout}\n{completed.stderr}")
        return completed

    if language in {"c", "cpp"}:
        standard = "-std=c11" if language == "c" else "-std=c++17"
        flags = [standard, "-O3", "-DNDEBUG", "-c"]
        if algorithm in {"pid", "pi_monte_carlo_estimation", "shunting_yard", "mandelbrot", "floatmm",
                         "almabench", "stanford_realmm", "matmul_f64_4x4"}:
            flags.append("-ffp-contract=off")
        if algorithm == "mandelbrot":
            flags.append("-fno-fast-math")
        run([compiler, *flags, str(source), "-o", str(artifact)])
    elif language == "c3":
        flags = ["-O3", "--no-entry"]
        run([compiler, "static-lib", str(source), *flags, "-o", "implementation",
             "--output-dir", str(directory), "--obj-out", str(directory)])
    elif language == "elisa":
        flags = ["-O3", "-emit", "obj"]
        run([compiler, *flags, "-o", str(artifact), str(source)])
    elif language == "nim":
        flags = ["--app:staticlib", "--noMain", "--mm:none", "-d:release"]
        if algorithm in {"pi_monte_carlo_estimation", "shunting_yard", "mandelbrot", "floatmm",
                         "almabench", "stanford_realmm", "matmul_f64_4x4"}:
            flags.append("--passC:-ffp-contract=off")
        if algorithm == "mandelbrot":
            flags.append("--passC:-fno-fast-math")
        compile_source = source
        if not algorithm[0].isalpha():
            compile_source = directory / f"module_{algorithm}.nim"
            compile_source.write_text(source.read_text(encoding="utf-8"), encoding="utf-8")
        run([compiler, "c", *flags,
             f"--nimcache:{directory / 'nimcache'}", f"--out:{artifact}", str(compile_source)])
    elif language == "odin":
        flags = ["-file", "-build-mode:obj", "-no-entry-point", "-o:speed", "-microarch:generic"]
        run([compiler, "build", str(source), *flags, f"-out:{artifact}"])
    elif language == "rust":
        flags = ["--edition=2021", "--crate-type=staticlib", "--print=native-static-libs", "-C", "opt-level=3",
                 "-C", "panic=abort", "-C", "target-cpu=generic"]
        compiled = run([compiler, *flags, "-o", str(artifact), str(source)])
        libraries = [line.partition("native-static-libs:")[2].strip()
                     for line in (compiled.stdout + compiled.stderr).splitlines()
                     if "native-static-libs:" in line]
        if len(libraries) != 1:
            raise RuntimeError("Rust compiler did not report its native static-library dependencies")
        native_link_flags = shlex.split(libraries[0])
    elif language == "v":
        flags = ["-prod", "-is_o", "-gc", "none", "-no-skip-unused", "-cc", c_compiler]
        if algorithm in {"shunting_yard", "mandelbrot", "floatmm", "almabench", "stanford_realmm",
                         "matmul_f64_4x4"}:
            flags.extend(["-cflags", "-ffp-contract=off"])
        if algorithm == "mandelbrot":
            flags.extend(["-cflags", "-fno-fast-math"])
        if algorithm == "stream_sieve":
            flags.append("-enable-globals")
        run([compiler, *flags,
             "-dump-c-flags", str(directory / "v-c-flags.txt"), "-o", str(artifact), str(source)])
    elif language == "zig":
        flags = ["-O", "ReleaseFast", "-mcpu=baseline"]
        run([compiler, "build-obj", *flags, f"-femit-bin={artifact}", str(source)])
    if not artifact.is_file():
        raise RuntimeError(f"compiler completed without creating {artifact}")

    for source_index, link_source in enumerate(extra_link_sources):
        link_source = link_source.resolve()
        if not link_source.is_file():
            raise ValueError(f"extra link source is missing: {link_source}")
        if link_source.suffix == ".o":
            extra_link_objects.append(link_source)
            continue
        link_object = directory / f"extra-link-{source_index}.o"
        run([c_compiler, "-std=c11", "-O3", "-DNDEBUG", "-c", str(link_source), "-o", str(link_object)])
        extra_link_objects.append(link_object)

    binaries = {}
    harnesses = family_harnesses if with_checker else family_harnesses[:1]
    for name in harnesses:
        harness = ROOT / "benchmarks" / "harness" / f"{name}.c"
        harness_object = directory / f"{name}.o"
        executable = directory / (name + (".exe" if os.name == "nt" else ""))
        workspace_flag = []
        null_empty_input_flag = (
            ["-DBENCHMARK_NULL_EMPTY_INPUT_MAY_WRITE"]
            if (name == "i64_array_bytes_output_check"
                and family == "i64_array_bytes_output"
                and algorithm in {"shannon_fano", "shannon_fano_compressor"})
            else [])
        if (name == "i64_array_bytes_output_check" and family == "i64_array_bytes_output"
                and "workspace" in spec):
            workspace_bytes = spec["workspace"].get("bytes")
            if type(workspace_bytes) is not int or not 1 <= workspace_bytes <= 400004:
                raise ValueError("workspace bytes must be an integer from 1 through 400004")
            workspace_flag = [f"-DBENCHMARK_WORKSPACE_BYTES={workspace_bytes}"]
        if (name == "i32_array_bytes_output_check" and family == "i32_array_bytes_output"
                and "workspace" in spec):
            workspace_bytes = spec["workspace"].get("bytes")
            if type(workspace_bytes) is not int or not 1 <= workspace_bytes <= 400004:
                raise ValueError("workspace bytes must be an integer from 1 through 400004")
            workspace_flag = [f"-DBENCHMARK_WORKSPACE_BYTES={workspace_bytes}"]
        harness_fp_flags = (["-ffp-contract=off"]
                            if algorithm == "pi_monte_carlo_estimation" else [])
        run([c_compiler, "-std=c11", "-O3", "-DNDEBUG", f"-DBENCHMARK_FUNCTION={function_symbol}",
             *harness_fp_flags, *workspace_flag, *null_empty_input_flag,
             "-c", str(harness), "-o", str(harness_object)])
        linker = compiler if language == "cpp" else c_compiler
        command = [linker, str(harness_object), str(artifact),
                   *(str(path) for path in extra_link_objects), "-o", str(executable), *native_link_flags]
        if os.name != "nt":
            command.append("-lm")
        if sys.platform.startswith("linux") and language in {"nim", "v"}:
            command.extend(["-ldl", "-pthread"])
        run(command)
        binaries[name] = {"path": str(executable), "sha256": sha256_file(executable),
                          "harness_sha256": sha256_file(harness)}

    version_command = [compiler, "version" if language in {"odin", "v"} else "--version"]
    version = subprocess.run(version_command, capture_output=True, text=True, timeout=30)
    compiler_hash = sha256_file(Path(compiler))
    compiler_version = (version.stdout + version.stderr).strip() if version.returncode == 0 else (
        f"version option unavailable; executable sha256={compiler_hash}")
    manifest = {
        "algorithm": algorithm, "function_symbol": function_symbol, "language": language, "family": family,
        "source_path": source.relative_to(ROOT).as_posix(), "source_sha256": sha256_file(source),
        "compiler": compiler, "compiler_version": compiler_version,
        "compiler_sha256": compiler_hash, "version_command": version_command,
        "version_exit_code": version.returncode,
        "build_flags": shlex.join(flags), "commands": commands,
        "native_link_flags": native_link_flags, "artifact": str(artifact), "binaries": binaries,
        "extra_link_sources": [
            {"path": path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else str(path),
             "sha256": sha256_file(path)}
            for path in (source.resolve() for source in extra_link_sources)
        ],
    }
    (directory / "build.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def main(family: str | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    if family is None:
        parser.add_argument("--family", required=True, choices=FAMILIES)
    else:
        parser.set_defaults(family=family)
    parser.add_argument("--algorithm", required=True)
    parser.add_argument("--language", required=True, choices=EXTENSIONS)
    parser.add_argument("--compiler", help="Override the language compiler executable, including Elisa")
    parser.add_argument("--cc", default="cc", help="C compiler used for the harness and C ABI link")
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--with-checker", action="store_true")
    args = parser.parse_args()
    letter = args.algorithm[0] if args.algorithm and args.algorithm[0].isalpha() else "0-9"
    directory = args.output_dir or ROOT / "build" / args.family / letter / args.algorithm / args.language
    try:
        manifest = build(args.algorithm, args.language, directory, compiler=args.compiler,
                         cc=args.cc, with_checker=args.with_checker, family=args.family)
    except (ValueError, RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        parser.exit(1, f"{error}\n")
    print(manifest["binaries"][FAMILIES[args.family][1][0]]["path"])
    print(f"build provenance: {directory.resolve() / 'build.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
