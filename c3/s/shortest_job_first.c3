module shortest_job_first;

const long MAX_JOBS = 32;
const long MAX_ARRIVAL = 64;
const long MAX_BURST = 128;
const long SENTINEL = 999999999;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long shortest_job_first(long* input, usz length, char* output, usz capacity) @export("shortest_job_first") {
    if (input == null || length < 1) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_JOBS || length != 1 + 2 * (usz)raw_count) return -1;
    usz count = (usz)raw_count;
    long[MAX_JOBS] remaining = {};
    long[MAX_JOBS] waiting = {};
    for (usz i = 0; i < count; i += 1) {
        if (input[1 + i] < 0 || input[1 + i] > MAX_ARRIVAL) return -1;
        long burst = input[1 + count + i];
        if (burst < 1 || burst > MAX_BURST || burst >= SENTINEL) return -1;
        remaining[i] = burst;
    }
    usz bytes = (1 + 2 * count) * 8;
    if (output == null || capacity < bytes) return -2;
    usz complete = 0;
    long time = 0, minimum = SENTINEL;
    usz short_index = 0;
    bool check = false;
    while (complete != count) {
        for (usz j = 0; j < count; j += 1) {
            if (input[1 + j] <= time && remaining[j] > 0 && remaining[j] < minimum) {
                minimum = remaining[j];
                short_index = j;
                check = true;
            }
        }
        if (!check) { time += 1; continue; }
        remaining[short_index] -= 1;
        minimum = remaining[short_index];
        if (minimum == 0) minimum = SENTINEL;
        if (remaining[short_index] == 0) {
            complete += 1;
            check = false;
            long finish_time = time + 1;
            long wait = finish_time - input[1 + short_index] - input[1 + count + short_index];
            waiting[short_index] = if wait > 0: wait else: 0;
        }
        time += 1;
    }
    put_i64_le(output, 0, raw_count);
    for (usz i = 0; i < count; i += 1) put_i64_le(output, 8 * (1 + i), waiting[i]);
    for (usz i = 0; i < count; i += 1) put_i64_le(output, 8 * (1 + count + i), input[1 + count + i] + waiting[i]);
    return (long)bytes;
}
