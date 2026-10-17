package list_queue

import "core:c"

MAX_QUEUE_SIZE :: 10
MAX_OPS :: 64
MAX_INPUT_LENGTH :: 129
MAX_OUTPUT_WORDS :: 130
MAX_OUTPUT_BYTES :: 520

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
    bits := u32(value)
    for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
list_queue :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    if input[0] < 0 || input[0] > i64(MAX_OPS) do return -1
    op_count := int(input[0])
    queue: [MAX_QUEUE_SIZE]i32
    words: [MAX_OUTPUT_WORDS]i32
    word_count := 1
    query_count := 0
    pos := 1
    queue_size := 0
    for op := 0; op < op_count; op += 1 {
        if pos >= int(length) do return -1
        opcode := input[pos]
        pos += 1
        if opcode == 0 {
            if pos >= int(length) do return -1
            raw := input[pos]
            pos += 1
            if raw < -2_147_483_648 || raw > 2_147_483_647 || queue_size >= MAX_QUEUE_SIZE do return -1
            queue[queue_size] = i32(raw)
            queue_size += 1
        } else if opcode == 1 {
            if queue_size == 0 {
                words[word_count] = 3
                words[word_count+1] = 0
            } else {
                value := queue[0]
                for i := 0; i < MAX_QUEUE_SIZE-1; i += 1 { queue[i] = queue[i+1] }
                queue_size -= 1
                words[word_count] = 1
                words[word_count+1] = value
            }
            word_count += 2
            query_count += 1
        } else if opcode == 2 {
            words[word_count] = 2
            words[word_count+1] = i32(queue_size)
            word_count += 2
            query_count += 1
        } else do return -1
    }
    if pos != int(length) || word_count+1+queue_size > MAX_OUTPUT_WORDS do return -1
    words[0] = i32(query_count)
    words[word_count] = i32(queue_size)
    word_count += 1
    for i := 0; i < queue_size; i += 1 { words[word_count] = queue[i]; word_count += 1 }
    bytes := word_count * 4
    if output == nil || capacity < c.size_t(bytes) do return -2
    buffer: [MAX_OUTPUT_BYTES]u8
    for i := 0; i < word_count; i += 1 { put_i32_le(&buffer[0], i*4, words[i]) }
    for i := 0; i < bytes; i += 1 { output[i] = buffer[i] }
    return i64(bytes)
}
