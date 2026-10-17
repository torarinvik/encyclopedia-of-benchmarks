module mlfqscheduler;

fn void put_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits >> (8 * byte)); }
}

fn long mlfqscheduler(long* input, usz length, uint8* output, usz output_capacity) @export("mlfqscheduler") {
    if (input == null || length < 2 || length > 55) { return -1; }
    long levels_value = input[0], process_count_value = input[1];
    if (levels_value < 1 || levels_value > 4 || process_count_value < 0 || process_count_value > 16) { return -1; }
    usz levels = (usz)levels_value, process_count = (usz)process_count_value;
    if (length != 2 + levels + 3 * process_count) { return -1; }
    long[4] quanta = zeroed;
    long[16] pids = zeroed, remaining = zeroed;
    for (usz level = 0; level < levels; level++) {
        quanta[level] = input[2 + level];
        if (quanta[level] < 1 || quanta[level] > 32) { return -1; }
    }
    usz process_offset = 2 + levels;
    for (usz i = 0; i < process_count; i++) {
        long pid = input[process_offset + 3 * i];
        long burst = input[process_offset + 3 * i + 1];
        long arrival = input[process_offset + 3 * i + 2];
        if (pid < -2147483648 || pid > 2147483647 || burst < 0 || burst > 1000 || arrival < 0 || arrival > 1000000) { return -1; }
        pids[i] = pid; remaining[i] = burst;
    }

    usz[64] queues = zeroed;
    usz[4] queue_counts = zeroed;
    for (usz i = 0; i < process_count; i++) { queues[i] = i; }
    queue_counts[0] = process_count;
    long[16] completion_pids = zeroed, completion_times = zeroed;
    usz completions = 0;
    long current_time = 0;
    while (true) {
        usz active = 0;
        for (usz level = 0; level < levels; level++) { active += queue_counts[level]; }
        if (active == 0) { break; }
        for (usz level = 0; level < levels; level++) {
            usz base = level * 16, queued = queue_counts[level];
            if (queued == 0) { continue; }
            usz process = queues[base];
            for (usz j = 1; j < queued; j++) { queues[base + j - 1] = queues[base + j]; }
            queue_counts[level]--;
            long slice = if quanta[level] < remaining[process] then quanta[level] else remaining[process];
            current_time += slice;
            remaining[process] -= slice;
            if (remaining[process] == 0) {
                completion_pids[completions] = pids[process];
                completion_times[completions] = current_time;
                completions++;
            } else {
                usz destination = if level + 1 < levels then level + 1 else level;
                queues[destination * 16 + queue_counts[destination]] = process;
                queue_counts[destination]++;
            }
        }
    }

    usz elements = 2 + 2 * completions, required = elements * 8;
    if (output == null || output_capacity < required) { return -2; }
    put_i64_le(output, 0, current_time); put_i64_le(output, 8, (long)completions);
    for (usz i = 0; i < completions; i++) {
        put_i64_le(output, 16 + 16 * i, completion_pids[i]);
        put_i64_le(output, 24 + 16 * i, completion_times[i]);
    }
    return (long)elements;
}
