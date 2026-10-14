# Find maximum

This benchmark scans a signed 64-bit array and returns its largest value.

## Contract

- Inputs contain 1 through 512 signed 64-bit integers.
- The result is the maximum value. An empty array or an array longer than 512 returns `-1`.
- The implementation scans left to right in O(n) time and constant extra space.

The pinned Python source provides iterative and divide-and-conquer versions and raises an error for an empty list. Other upstream APIs and numeric types vary. The local contract uses the iterative scan and the shared array-scalar ABI; the -1 empty-input sentinel is also a valid result for arrays whose maximum is -1, so callers use the array length to distinguish that case.

## Inspected upstream sources

- [Dart — `maths/find_max.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/find_max.dart)
- [Java — `src/main/java/com/thealgorithms/maths/FindMax.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FindMax.java)
- [Python — `maths/find_max.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/find_max.py)
- [Ruby — `maths/find_max.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/find_max.rb)
- [Scala — `src/main/scala/Mathematics/FindMax.scala`](https://github.com/TheAlgorithms/Scala/blob/de555349d5effb87962d3116eb08c9f374065112/src/main/scala/Mathematics/FindMax.scala)

## Workload and verification

`workload.json` covers empty and singleton arrays, sorted and reversed inputs, duplicates, all-negative values, and signed 64-bit boundaries. [`verify_find_min_max.py`](../../verify_find_min_max.py) checks exhaustive short arrays, deterministic random arrays, the length limit, and every workload case in all nine languages.

Build and record with the `i64_array_scalar` ABI family. Source ports are in `f/` in all nine language directories.
