# Benchmarking

Every compared implementation must use the same algorithm contract, workload cases, and language-neutral ABI. The search benchmarks expose a named function with this signature (substitute the algorithm's name):

```c
int64_t algorithm_name(const int64_t *values, size_t length, int64_t target);
```

The shared C11 search runner in `benchmarks/harness/runner.c` generates the declared deterministic input, checks the result before timing, runs warmups, gathers raw nanosecond samples with C `clock()` process CPU time, and consumes returned values into a checksum. Compile it with `-DBENCHMARK_FUNCTION=<algorithm_name>` so it links to the desired implementation. `benchmarks/run.py` reads the workload file, runs the linked executable once per case, and appends JSON Lines records. Output defaults to `results/<letter>/<algorithm>/<language>.jsonl`.

## Build the current C and C++ implementations

Run commands from the repository root. The examples use portable optimization flags and contain no CPU-specific tuning.

```sh
mkdir -p build
cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=linear_search benchmarks/harness/runner.c c/l/linear_search.c -o build/linear_search_c
```

```sh
mkdir -p build
cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=linear_search -c benchmarks/harness/runner.c -o build/linear_search_runner.o
c++ -std=c++17 -O3 -DNDEBUG -c cpp/l/linear_search.cpp -o build/linear_search_impl.o
c++ build/linear_search_runner.o build/linear_search_impl.o -o build/linear_search_cpp
```

Then record a run. Compiler metadata is supplied explicitly because compiler naming and version reporting differ across toolchains.

```sh
python3 benchmarks/run.py \
  --algorithm linear_search \
  --language c \
  --source c/l/linear_search.c \
  --executable build/linear_search_c \
  --compiler cc \
  --compiler-version "$(cc --version | head -n 1)" \
  --build-flags '-std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=linear_search' \
  --build-command 'cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=linear_search benchmarks/harness/runner.c c/l/linear_search.c -o build/linear_search_c'
```

For another search algorithm, use its same-named exported function and define it when compiling the runner. For example, the binary-search workload uses an ascending array and the same ABI:

```sh
cc -std=c11 -O3 -DNDEBUG -DBENCHMARK_FUNCTION=binary_search benchmarks/harness/runner.c c/b/binary_search.c -o build/binary_search_c
```

Replace language, source, compiler details, and build command for other implementations. A linked executable must export the same C ABI symbol. The current ports declare this ABI; per-compiler object and link recipes for C3, Elisa, Nim, Odin, Rust, V, and Zig still need to be documented as their build flows are established.

The workloads default to seven samples and two warmup rounds. Repetitions are chosen from a workload-specific comparison model so each sample does roughly the same comparison work across cases. These settings can be overridden with `--samples`, `--warmups`, and `--target-comparisons`; the chosen values are included in output records. The input is reused between calls, so these workloads measure repeated searches over the same array. Timing excludes process startup, input generation, correctness checks, and JSON serialization.

Result records follow [`benchmarks/results.schema.json`](benchmarks/results.schema.json). The runner uses `clock()`, so samples are process CPU time and timer resolution depends on the C runtime. Compare runs on the same host and runtime when studying small differences. The harness records the timer resolution alongside every case.

Do not use `-march=native`, Intel-specific intrinsics, or other host-specific tuning for the portable baseline. A separately labeled optimized variant can be added later, with its exact compiler flags recorded separately.
