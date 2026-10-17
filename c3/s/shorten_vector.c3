module shorten_vector;

const usz MAX_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 67;

fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn bool is_removed(long value, long* input, usz n, usz by) {
    if (by == 0) return true;
    usz suffix_start = n - by;
    for (usz key = suffix_start; key < n; key += 1) {
        if (value == input[2 + key]) return true;
    }
    return false;
}

fn long shorten_vector(long* input, usz length, char* output, usz capacity) @export("shorten_vector") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_n = input[0], raw_by = input[1];
    if (raw_n < 0 || raw_n > 64 || raw_by < 0 || raw_by > raw_n) return -1;
    usz n = (usz)raw_n, by = (usz)raw_by;
    if (length != 2 + n) return -1;
    for (usz i = 0; i < n; i += 1) {
        if (input[2 + i] < -1000000 || input[2 + i] > 1000000) return -1;
    }

    usz survivor_count = 0;
    for (usz i = 0; i < n; i += 1) {
        if (!is_removed(input[2 + i], input, n, by)) survivor_count += 1;
    }
    usz bytes = survivor_count * 8;
    if (output == null || capacity < bytes) return -2;

    usz written = 0;
    for (usz i = 0; i < n; i += 1) {
        long value = input[2 + i];
        if (!is_removed(value, input, n, by)) {
            put_i64_le(value, output, written * 8);
            written += 1;
        }
    }
    return (long)bytes;
}
