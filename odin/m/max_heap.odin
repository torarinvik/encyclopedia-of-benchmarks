package max_heap

import "core:c"

MAX_OPERATIONS :: 512
MAX_INSERTIONS :: 256

store_i64_le :: proc "c" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
max_heap :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || input[0] < 0 || input[0] > MAX_OPERATIONS do return -1
    operations := int(input[0])
    if int(length) != 1 + operations * 2 do return -1
    inserts, words: int
    for i := 0; i < operations; i += 1 {
        op, value := input[1 + 2 * i], input[2 + 2 * i]
        if op < 0 || op > 2 do return -1
        if op == 0 { inserts += 1; if inserts > MAX_INSERTIONS || value < -2147483648 || value > 2147483647 do return -1 }
        else { if value != 0 do return -1; words += 1 }
    }
    if int(capacity) < words * 8 || (words > 0 && output == nil) do return -2
    heap: [MAX_INSERTIONS]i64
    size, out_index: int
    for i := 0; i < operations; i += 1 {
        op, value := input[1 + 2 * i], input[2 + 2 * i]
        if op == 0 {
            at := size; heap[at] = value; size += 1
            for at > 0 { parent := (at - 1) / 2; if heap[parent] >= heap[at] do break; temp := heap[parent]; heap[parent] = heap[at]; heap[at] = temp; at = parent }
            continue
        }
        result := i64(-9223372036854775807) - 1
        if size > 0 {
            result = heap[0]
            if op == 2 { size -= 1; heap[0] = heap[size]; at := 0
                for at < size / 2 { child := at * 2 + 1; if child + 1 < size && heap[child + 1] > heap[child] do child += 1; if heap[at] >= heap[child] do break; temp := heap[at]; heap[at] = heap[child]; heap[child] = temp; at = child }
            }
        }
        store_i64_le(output, out_index * 8, result); out_index += 1
    }
    return i64(words)
}
