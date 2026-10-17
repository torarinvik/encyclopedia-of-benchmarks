module slack_time_scheduling;

const usz MAX_N = 64;
const long MAX_TIME = 1000000;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long slack_time_scheduling(long* input, usz length, char* output, usz capacity)
    @export("slack_time_scheduling") {
    if (input == null || length < 1 || length > 129) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 2 * n) return -1;
    long[MAX_N] slack;
    usz[MAX_N] order;
    for (usz i = 0; i < n; i++) {
        long execution = input[1 + 2 * i];
        long deadline = input[2 + 2 * i];
        if (execution < 0 || execution > MAX_TIME || deadline < 0 || deadline > MAX_TIME) return -1;
        slack[i] = deadline - execution;
        order[i] = i;
    }
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 1; i < n; i++) {
        usz key = order[i];
        usz j = i;
        while (j > 0 && slack[key] < slack[order[j - 1]]) { order[j] = order[j - 1]; j--; }
        order[j] = key;
    }
    for (usz i = 0; i < n; i++) store_i64_le(output, i * 8, (long)order[i]);
    return (long)bytes;
}
