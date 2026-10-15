# Collatz Sequence Length

This benchmark returns the number of transitions needed for the Collatz sequence to reach 1. For an even value the next value is `n / 2`; for an odd value it is `3n + 1`. It uses the same sequence rule as the pinned C and Dart candidates. The C candidate prints the sequence and its step count, while the Dart candidate prints the sequence; the benchmark measures the shared transition-count operation.

The shared contract accepts signed 64-bit inputs from 1 through 1,000,000 and returns `-1` outside that range. The ports use signed 64-bit intermediate values; every supported starting value reaches 1 without overflowing that type.

Run the scalar correctness corpus with:

```sh
python3 benchmarks/verify_scalar.py --algorithms collatz --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

Run benchmark records with the standard scalar build and recorder scripts. Workload cases are in `workload.json`.

Upstream references: [TheAlgorithms/C `math/collatz.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/collatz.c) and [TheAlgorithms/Dart `other/collatz.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/collatz.dart).
