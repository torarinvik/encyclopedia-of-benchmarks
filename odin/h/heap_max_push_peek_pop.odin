package heap_max_push_peek_pop

import "core:c"

sift_down :: proc "contextless" (heap: [^]i64, count, start: int) {
    index := start
    for {
        largest := index
        left := index * 2 + 1
        right := left + 1
        if left < count && heap[left] > heap[largest] do largest = left
        if right < count && heap[right] > heap[largest] do largest = right
        if largest == index do return
        heap[index], heap[largest] = heap[largest], heap[index]
        index = largest
    }
}
store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
heap_max_push_peek_pop :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 257 do return -1
    raw_count := values[0]
    if raw_count < 1 || raw_count > 256 || length != c.size_t(raw_count + 1) do return -1
    count := int(raw_count)
    heap: [256]i64
    for index := 0; index < count; index += 1 {
        value := values[index + 1]
        if value < 1 || value > 1000000000 do return -1
        position := index
        heap[position] = value
        for position > 0 {
            parent := (position - 1) / 2
            if heap[parent] >= heap[position] do break
            heap[parent], heap[position] = heap[position], heap[parent]
            position = parent
        }
    }
    output_bytes := 8 * count
    if output == nil || output_capacity < c.size_t(output_bytes) do return -2
    remaining := count
    for index := 0; index < count; index += 1 {
        store_i64_le(output, 8 * index, heap[0])
        remaining -= 1
        if remaining > 0 { heap[0] = heap[remaining]; sift_down(&heap[0], remaining, 0) }
    }
    return i64(output_bytes)
}
