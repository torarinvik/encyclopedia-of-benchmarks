module preemptive_priority_scheduling;

const int MAX_PROCESSES = 8;
const usz MAX_OUTPUT_WORDS = 81;

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long preemptive_priority_scheduling(int* input, usz length, char* output, usz capacity)
    @export("preemptive_priority_scheduling") {
    if (input == null || length < 1 || length > 33) return -1;
    int process_count = input[0];
    if (process_count < 0 || process_count > MAX_PROCESSES || length != 1 + 4 * (usz)process_count) return -1;

    int[MAX_PROCESSES] ids;
    int[MAX_PROCESSES] arrivals;
    int[MAX_PROCESSES] remaining;
    int[MAX_PROCESSES] priorities;
    bool[MAX_PROCESSES] seen_ids = zeroed;
    for (usz i = 0; i < (usz)process_count; i += 1) {
        usz offset = 1 + 4 * i;
        int id = input[offset], arrival = input[offset + 1], burst = input[offset + 2], priority = input[offset + 3];
        if (id < 0 || id >= MAX_PROCESSES || seen_ids[id] || arrival < 0 || arrival > 16 || burst < 1 || burst > 8) return -1;
        for (usz previous = 0; previous < i; previous += 1)
            if (priorities[previous] == priority && arrivals[previous] == arrival) return -1;
        seen_ids[id] = true;
        ids[i] = id;
        arrivals[i] = arrival;
        remaining[i] = burst;
        priorities[i] = priority;
    }

    int[80] schedule;
    usz tick_count = 0, completed = 0;
    while (completed < (usz)process_count) {
        usz best = (usz)process_count;
        for (usz i = 0; i < (usz)process_count; i += 1) {
            if (remaining[i] <= 0 || arrivals[i] > (int)tick_count) continue;
            if (best == (usz)process_count || priorities[i] > priorities[best] ||
                (priorities[i] == priorities[best] && arrivals[i] < arrivals[best])) best = i;
        }
        if (best == (usz)process_count) schedule[tick_count] = -1;
        else {
            schedule[tick_count] = ids[best];
            remaining[best] -= 1;
            if (remaining[best] == 0) completed += 1;
        }
        tick_count += 1;
    }

    usz bytes = (1 + tick_count) * 4;
    if (output == null || capacity < bytes) return -2;
    char[81 * 4] buffer;
    put_i32_le(&buffer[0], 0, (int)tick_count);
    for (usz i = 0; i < tick_count; i += 1) put_i32_le(&buffer[0], 4 * (i + 1), schedule[i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
