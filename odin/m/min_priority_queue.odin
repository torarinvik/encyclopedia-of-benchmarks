package min_priority_queue

import "core:c"

MAX_CAPACITY :: 64
MAX_OPS :: 64
MAX_INPUT_LENGTH :: 130
MAX_OUTPUT_WORDS :: 1 + 2 * MAX_OPS
MAX_OUTPUT_BYTES :: 4 * MAX_OUTPUT_WORDS

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
    bits := u32(value)
    for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
min_priority_queue :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    if input[0] < 0 || input[0] > i64(MAX_CAPACITY) || input[1] < 0 || input[1] > i64(MAX_OPS) do return -1

    capacity := int(input[0])
    operation_count := int(input[1])
    heap: [MAX_CAPACITY]i32
    words: [MAX_OUTPUT_WORDS]i32
    heap_size := 0
    word_count := 1
    query_count := 0
    pos := 2

    for op := 0; op < operation_count; op += 1 {
        if pos >= int(length) do return -1
        opcode := input[pos]
        pos += 1
        if opcode == 0 {
            if pos >= int(length) do return -1
            raw := input[pos]
            pos += 1
            if raw < -2_147_483_648 || raw > 2_147_483_647 || heap_size >= capacity do return -1
            index := heap_size
            heap[index] = i32(raw)
            for index > 0 {
                parent := (index - 1) / 2
                if heap[parent] <= heap[index] do break
                tmp := heap[parent]
                heap[parent] = heap[index]
                heap[index] = tmp
                index = parent
            }
            heap_size += 1
        } else if opcode == 1 || opcode == 2 {
            if heap_size == 0 do return -1
            value := heap[0]
            if opcode == 2 {
                heap_size -= 1
                if heap_size > 0 {
                    heap[0] = heap[heap_size]
                    index := 0
                    for {
                        left := 2*index + 1
                        if left >= heap_size do break
                        right := left + 1
                        child := left
                        if right < heap_size && heap[right] < heap[left] do child = right
                        if heap[index] <= heap[child] do break
                        tmp := heap[index]
                        heap[index] = heap[child]
                        heap[child] = tmp
                        index = child
                    }
                }
            }
            words[word_count] = i32(opcode)
            words[word_count+1] = value
            word_count += 2
            query_count += 1
        } else if opcode == 3 || opcode == 4 {
            words[word_count] = i32(opcode)
            if opcode == 3 {
                if heap_size == 0 { words[word_count+1] = 1 } else { words[word_count+1] = 0 }
            } else {
                if heap_size == capacity { words[word_count+1] = 1 } else { words[word_count+1] = 0 }
            }
            word_count += 2
            query_count += 1
        } else do return -1
    }

    if pos != int(length) || word_count > MAX_OUTPUT_WORDS do return -1
    words[0] = i32(query_count)
    bytes := word_count * 4
    if output == nil || output_capacity < c.size_t(bytes) do return -2
    buffer: [MAX_OUTPUT_BYTES]u8
    for i := 0; i < word_count; i += 1 { put_i32_le(&buffer[0], i*4, words[i]) }
    for i := 0; i < bytes; i += 1 { output[i] = buffer[i] }
    return i64(bytes)
}
