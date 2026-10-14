#!/usr/bin/env python3
"""Build one scalar implementation and its C ABI runner using portable flags."""

# Keep the original scalar CLI and imports stable while sharing compiler recipes
# with graph benchmarks. The workload family check prevents ABI mismatches.
from build_abi import COMPILERS, EXTENSIONS, ROOT, build, main, sha256_file


if __name__ == "__main__":
    raise SystemExit(main("scalar"))
