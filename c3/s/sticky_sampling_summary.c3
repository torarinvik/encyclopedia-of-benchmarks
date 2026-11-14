module sticky_sampling_summary;

fn void sticky_put(char* out, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz j = 0; j < 8; j++) { out[offset+j] = (char)(bits & 255); bits >>= 8; }
}

fn long sticky_sampling_summary(long* input, usz length, char* output, usz capacity) @export("sticky_sampling_summary") {
    if (input == null || length < 3 || length > 323 || input[0] < 1 || input[0] > 8 ||
        input[1] < 0 || input[1] > 64 || input[2] < 0 || input[2] > 256) return -1;
    usz t = (usz)input[0], n = (usz)input[1], k = (usz)input[2];
    if (length != 3+n+k) return -1;
    for (usz i = 0; i < n; i++) if (input[3+i] < 0 || input[3+i] > 15) return -1;
    for (usz i = 0; i < k; i++) if (input[3+n+i] < 0 || input[3+n+i] > 255) return -1;
    long[16] counts = {};
    usz cursor = 0, rate = 1, end = 2*t;
    for (usz i = 0; i < n; i++) {
        if (i == end) {
            rate *= 2; end += rate*t;
            for (usz item = 0; item < 16; item++) {
                while (counts[item] != 0) {
                    if (cursor == k) return -1;
                    long draw = input[3+n+cursor]; cursor++;
                    if ((draw & 1) != 0) break;
                    counts[item]--;
                }
            }
        }
        usz item = (usz)input[3+i];
        if (counts[item] != 0) counts[item]++;
        else {
            if (cursor == k) return -1;
            usz draw = (usz)input[3+n+cursor]; cursor++;
            if (draw % rate == 0) counts[item] = 1;
        }
    }
    if (cursor != k) return -1;
    usz active = 0;
    for (usz i = 0; i < 16; i++) if (counts[i] != 0) active++;
    usz bytes = 8+16*active;
    if (output == null || capacity < bytes) return -2;
    sticky_put(output, 0, (long)active);
    usz offset = 8;
    for (usz i = 0; i < 16; i++) if (counts[i] != 0) {
        sticky_put(output, offset, (long)i); sticky_put(output, offset+8, counts[i]); offset += 16;
    }
    return (long)bytes;
}
