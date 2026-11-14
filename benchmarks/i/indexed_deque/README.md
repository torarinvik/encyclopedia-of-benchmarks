# Indexed circular deque

This bounded trace combines insertion and removal at both ends with indexed
reads. [`linked_deque`](../../l/linked_deque/README.md) does not offer indexed
reads, while [`ring_buffer`](../../r/ring_buffer/README.md) offers indexed
reads but only FIFO insertion and removal. A circular array supports all five
operations in constant time without moving existing elements.

Input to the `i64_array_bytes_output` ABI is `[q,(opcode,argument)[q]]`, with
`1 <= q <= 256` and a capacity of 256. Opcodes 0 and 1 insert a value in
`[-1000000,1000000]` at the front and back, respectively. Opcodes 2 and 3
remove the front and back, respectively, and require argument zero. Opcode 4
reads the zero-based logical index in its argument. Removal and lookup require
a nonempty deque; lookup also requires an index below its current size. The
trace must contain at least one indexed read. Emit one little-endian signed
64-bit word for each read. Invalid or null input returns `-1`; null or short
output returns `-2`; errors write nothing. Maximum valid input length is 513
words. At most 255 reads can occur because an insertion must precede them,
so the largest attainable output is 2040 bytes; the suite reserves 2048.

The primary maintains a head index and size over a fixed circular array. Each
operation takes O(1) time and the full trace takes O(q) time, with O(q) bounded
storage. The reference uses an ordinary list with front insertion and removal,
which shifts elements and deliberately differs from the circular implementation.

The [Library Checker deque task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/deque/task.md)
inspired the operation set. Its repository declares Apache-2.0; this bounded
contract, implementation, and reference are independently written.

Status: drafts in all ten supported languages, a direct reference, workload,
and suite registration are present. Nothing has been compiled or run.
