# Number container system

This benchmark follows the pinned Python `NumberContainer` behavior: `change(index, number)` replaces any prior value at an index, and `find(number)` returns the smallest index currently holding that number or `-1`. The original maintains a sorted index list for each number, using binary search for insertion and deletion; the bounded ports preserve the same observable operations.

Input is `[operation_count, op, a, b, ...]`, with at most 32 operations. A change is `[0, index, number]` where index is 0–63 and number is -100–100. A find is `[1, number, 0]`; the final zero is reserved. Output is the comma-separated results of find operations in order. Invalid input returns `-1`; insufficient output capacity returns `-2`. See `number_container_system_oracle.py` for the runtime oracle.
