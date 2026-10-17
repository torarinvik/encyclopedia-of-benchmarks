module round_robin;

const long MAX_JOBS = 32;
const long MAX_BURST = 4096;
const long QUANTUM = 2;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long round_robin(long* input, usz length, char* output, usz capacity) @export("round_robin") {
    if (input == null || length < 1) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_JOBS || length != (usz)raw_count + 1) return -1;
    usz count = (usz)raw_count;
    long[MAX_JOBS] remaining = {};
    long[MAX_JOBS] waiting = {};
    for (usz i = 0; i < count; i += 1) {
        long burst = input[i + 1];
        if (burst < 0 || burst > MAX_BURST) return -1;
        remaining[i] = burst;
    }
    usz bytes = (1 + 2 * count) * 8;
    if (output == null || capacity < bytes) return -2;
    long elapsed = 0;
    while (true) {
        bool done = true;
        for (usz i = 0; i < count; i += 1) {
            if (remaining[i] > 0) {
                done = false;
                if (remaining[i] > QUANTUM) {
                    elapsed += QUANTUM;
                    remaining[i] -= QUANTUM;
                } else {
                    elapsed += remaining[i];
                    waiting[i] = elapsed - input[i + 1];
                    remaining[i] = 0;
                }
            }
        }
        if (done) break;
    }
    put_i64_le(output, 0, raw_count);
    for (usz i = 0; i < count; i += 1) put_i64_le(output, 8 * (1 + i), waiting[i]);
    for (usz i = 0; i < count; i += 1) put_i64_le(output, 8 * (1 + count + i), input[i + 1] + waiting[i]);
    return (long)bytes;
}
