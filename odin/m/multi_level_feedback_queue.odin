package multi_level_feedback_queue

import "core:c"

MAX_QUEUES :: 4
MAX_PROCESSES :: 8
MAX_INPUT_WORDS :: 13
MAX_OUTPUT_WORDS :: 1 + 4 * MAX_PROCESSES
MAX_OUTPUT_BYTES :: 4 * MAX_OUTPUT_WORDS

Process :: struct { id, remaining, waiting, turnaround, stop_time: i32 }

put_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
    bits := u32(value)
    for byte := 0; byte < 4; byte += 1 { output[offset+byte] = u8(bits >> u32(8*byte)) }
}

@(export)
multi_level_feedback_queue :: proc "c" (input: [^]i32, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_INPUT_WORDS) do return -1
    queue_count := input[0]
    process_count := input[1]
    if queue_count < 1 || queue_count > MAX_QUEUES || process_count < 0 || process_count > MAX_PROCESSES do return -1
    if int(length) != 2 + int(queue_count-1) + int(process_count) do return -1

    slices: [MAX_QUEUES-1]i32
    pos := 2
    for i := 0; i < int(queue_count-1); i += 1 {
        if input[pos] < 1 || input[pos] > 16 do return -1
        slices[i] = input[pos]
        pos += 1
    }
    ready: [MAX_PROCESSES]Process
    ready_count := int(process_count)
    for i := 0; i < int(process_count); i += 1 {
        burst := input[pos]
        pos += 1
        if burst < 1 || burst > 16 do return -1
        ready[i] = Process{id=i32(i), remaining=burst, waiting=0, turnaround=0, stop_time=0}
    }

    finished: [MAX_PROCESSES]Process
    finished_count := 0
    current_time := 0
    for level := 0; level < int(queue_count-1); level += 1 {
        next_ready: [MAX_PROCESSES]Process
        next_count := 0
        time_slice := slices[level]
        for i := 0; i < ready_count; i += 1 {
            process := ready[i]
            process.waiting += current_time - process.stop_time
            if process.remaining > time_slice {
                current_time += time_slice
                process.remaining -= time_slice
                process.stop_time = current_time
                next_ready[next_count] = process
                next_count += 1
            } else {
                current_time += process.remaining
                process.remaining = 0
                process.stop_time = current_time
                process.turnaround = current_time
                finished[finished_count] = process
                finished_count += 1
            }
        }
        ready_count = next_count
        for i := 0; i < next_count; i += 1 { ready[i] = next_ready[i] }
    }
    for i := 0; i < ready_count; i += 1 {
        process := ready[i]
        process.waiting += current_time - process.stop_time
        current_time += process.remaining
        process.remaining = 0
        process.stop_time = current_time
        process.turnaround = current_time
        finished[finished_count] = process
        finished_count += 1
    }

    if finished_count != int(process_count) do return -1
    words: [MAX_OUTPUT_WORDS]i32
    word_count := 1
    words[0] = process_count
    for i := 0; i < finished_count; i += 1 {
        words[word_count] = finished[i].id
        words[word_count+1] = finished[i].waiting
        words[word_count+2] = finished[i].turnaround
        words[word_count+3] = finished[i].stop_time
        word_count += 4
    }
    bytes := word_count * 4
    if output == nil || capacity < c.size_t(bytes) do return -2
    buffer: [MAX_OUTPUT_BYTES]u8
    for i := 0; i < word_count; i += 1 { put_i32_le(&buffer[0], i*4, words[i]) }
    for i := 0; i < bytes; i += 1 { output[i] = buffer[i] }
    return i64(bytes)
}
