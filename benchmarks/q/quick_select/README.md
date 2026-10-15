# Quickselect

Quickselect partitions a collection around a pivot and continues only in the partition that contains the requested order statistic. This benchmark selects the upper median: the element at zero-based sorted index `floor(length / 2)`. It uses a median-of-three pivot and a three-way partition, and works on a local copy because the shared array-scalar ABI provides read-only input.

## Contract

- Input is zero to 1,024 signed 64-bit integers.
- Empty input or input longer than 1,024 returns `-1`; otherwise the result is the upper median. The caller uses the input length to distinguish an empty-input result from a valid median equal to `-1`.
- Duplicate values and the full signed 64-bit range are supported.
- The local copy uses bounded stack storage. Average running time is O(n); worst-case running time is O(n²) for deterministic pivot selection.

## Reviewed TheAlgorithms sources

The pinned Python source chooses a random pivot, creates less/equal/greater partitions, and recursively adjusts the requested index. JavaScript and TypeScript partition their mutable arrays in place. Java uses a median-of-medians pivot. The shared benchmark standardizes the zero-based selection semantics and upper-median rank, with a deterministic median-of-three three-way partition on a copied array.

- [Java — `QuickSelect.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/QuickSelect.java)
- [JavaScript — `QuickSelect.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Array/QuickSelect.js)
- [Python — `quick_select.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/quick_select.py)
- [Rust — `quick_select.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/searching/quick_select.rs)
- [TypeScript — `quick_select.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/sorts/quick_select.ts)

## Workload

`workload.json` includes empty, singleton, sorted, reverse-sorted, duplicate-heavy, all-equal, and signed-boundary inputs, plus deterministic modular-affine arrays of lengths 16, 256, and 1,024. Build and record with the `i64_array_scalar` ABI family. The nine portable source files are under `q/` in each target language folder.
