package mlfqscheduler

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@(export)
mlfqscheduler :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 55 do return -1
    levels_value := input[0]
    process_count_value := input[1]
    if levels_value < 1 || levels_value > 4 || process_count_value < 0 || process_count_value > 16 do return -1
    levels := int(levels_value)
    process_count := int(process_count_value)
    if length != c.size_t(2 + levels + 3 * process_count) do return -1
    quanta: [4]i64 = {}
    pids: [16]i64 = {}
    remaining: [16]i64 = {}
    for level := 0; level < levels; level += 1 {
        quanta[level] = input[2 + level]
        if quanta[level] < 1 || quanta[level] > 32 do return -1
    }
    process_offset := 2 + levels
    for i := 0; i < process_count; i += 1 {
        pid := input[process_offset + 3 * i]
        burst := input[process_offset + 3 * i + 1]
        arrival := input[process_offset + 3 * i + 2]
        if pid < -2_147_483_648 || pid > 2_147_483_647 || burst < 0 || burst > 1000 || arrival < 0 || arrival > 1_000_000 do return -1
        pids[i] = pid
        remaining[i] = burst
    }

    queues: [64]int = {}
    queue_counts: [4]int = {}
    for i := 0; i < process_count; i += 1 { queues[i] = i }
    queue_counts[0] = process_count
    completion_pids: [16]i64 = {}
    completion_times: [16]i64 = {}
    completions := 0
    current_time := i64(0)
    running := true
    for running {
        active := 0
        for level := 0; level < levels; level += 1 { active += queue_counts[level] }
        if active == 0 { running = false; continue }
        for level := 0; level < levels; level += 1 {
            base := level * 16
            queued := queue_counts[level]
            if queued == 0 { continue }
            process := queues[base]
            for j := 1; j < queued; j += 1 { queues[base + j - 1] = queues[base + j] }
            queue_counts[level] -= 1
            slice := quanta[level]
            if remaining[process] < slice { slice = remaining[process] }
            current_time += slice
            remaining[process] -= slice
            if remaining[process] == 0 {
                completion_pids[completions] = pids[process]
                completion_times[completions] = current_time
                completions += 1
            } else {
                destination := level
                if level + 1 < levels { destination = level + 1 }
                queues[destination * 16 + queue_counts[destination]] = process
                queue_counts[destination] += 1
            }
        }
    }

    elements := 2 + 2 * completions
    required := elements * 8
    if output == nil || output_capacity < c.size_t(required) do return -2
    put_i64_le(output, 0, current_time)
    put_i64_le(output, 8, i64(completions))
    for i := 0; i < completions; i += 1 {
        put_i64_le(output, 16 + 16 * i, completion_pids[i])
        put_i64_le(output, 24 + 16 * i, completion_times[i])
    }
    return i64(elements)
}
