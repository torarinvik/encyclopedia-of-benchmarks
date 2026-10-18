package priority_queue

import "core:c"

MAX_OPS :: 64
MAX_INPUT :: 130
MAX_OUTPUT :: 256

@(export)
priority_queue :: proc "c" (input: [^]i64, input_length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || input_length == 0 || input_length > MAX_INPUT do return -1
    if input[0] < 0 || input[0] > MAX_OPS do return -1
    op_count := int(input[0])
    heap: [MAX_OPS]i32
    seen: [MAX_OPS]i32
    staged: [MAX_OUTPUT]u8
    heap_size, seen_count, offset, output_size := 0, 0, 1, 0
    for k in 0..<op_count {
        if c.size_t(offset) >= input_length do return -1
        op := input[offset]
        offset += 1
        if op == 0 {
            if c.size_t(offset) >= input_length do return -1
            raw := input[offset]
            offset += 1
            if raw < -2147483648 || raw > 2147483647 do return -1
            value := i32(raw)
            for j in 0..<seen_count { if seen[j] == value do return -1 }
            seen[seen_count] = value
            seen_count += 1
            i := heap_size
            heap_size += 1
            heap[i] = value
            for i > 0 {
                parent := (i - 1) / 2
                if heap[parent] <= heap[i] do break
                heap[parent], heap[i] = heap[i], heap[parent]
                i = parent
            }
        } else if op == 1 || op == 2 {
            if heap_size == 0 do return -1
            bits := u32(heap[0])
            staged[output_size] = u8(bits & 0xff); output_size += 1
            staged[output_size] = u8((bits >> 8) & 0xff); output_size += 1
            staged[output_size] = u8((bits >> 16) & 0xff); output_size += 1
            staged[output_size] = u8((bits >> 24) & 0xff); output_size += 1
            if op == 2 {
                heap_size -= 1
                heap[0] = heap[heap_size]
                i := 0
                for i < heap_size {
                    child := 2 * i + 1
                    if child >= heap_size do break
                    if child + 1 < heap_size && heap[child + 1] < heap[child] do child += 1
                    if heap[i] <= heap[child] do break
                    heap[i], heap[child] = heap[child], heap[i]
                    i = child
                }
            }
        } else {
            return -1
        }
    }
    if c.size_t(offset) != input_length do return -1
    if output == nil || capacity < c.size_t(output_size) do return -2
    for i in 0..<output_size { output[i] = staged[i] }
    return i64(output_size)
}
