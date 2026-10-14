# Find minimum

This benchmark scans a signed 64-bit array and returns its smallest value.

## Contract

- Inputs contain 1 through 512 signed 64-bit integers.
- The result is the minimum value. An empty array or an array longer than 512 returns `-1`.
- The implementation scans left to right in O(n) time and constant extra space.

The pinned Python source provides iterative and divide-and-conquer versions and raises an error for an empty list. Other upstream APIs and numeric types vary. The local contract uses the iterative scan and the shared array-scalar ABI; the -1 empty-input sentinel is also a valid result for arrays whose minimum is -1, so callers use the array length to distinguish that case.

## Inspected upstream sources

- [Dart — `maths/find_min.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/find_min.dart)
- [Java — `src/main/java/com/thealgorithms/maths/FindMin.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FindMin.java)
- [JavaScript — `Maths/FindMin.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/FindMin.js)
- [Python — `maths/find_min.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/find_min.py)
- [Ruby — `maths/find_min.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/find_min.rb)
- [Scala — `src/main/scala/Mathematics/FindMin.scala`](https://github.com/TheAlgorithms/Scala/blob/de555349d5effb87962d3116eb08c9f374065112/src/main/scala/Mathematics/FindMin.scala)
- [TypeScript — `maths/find_min.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/find_min.ts)

## Workload and verification

`workload.json` covers empty and singleton arrays, sorted and reversed inputs, duplicates, all-negative values, and signed 64-bit boundaries. [`verify_find_min_max.py`](../../verify_find_min_max.py) checks exhaustive short arrays, deterministic random arrays, the length limit, and every workload case in all nine languages.

Build and record with the `i64_array_scalar` ABI family. Source ports are in `f/` in all nine language directories.
