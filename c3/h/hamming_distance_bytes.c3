module hamming_distance_bytes;

const MAX_BYTE_LENGTH = 1024;

// Count differing byte positions in two equal-length byte strings.
fn long hamming_distance_bytes(long* values, usz length) @export("hamming_distance_bytes") {
    if (values == null || length < 1 || length > 2050) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > MAX_BYTE_LENGTH ||
        length != 1 + 2 * (usz)count_value) return -1;
    usz count = (usz)count_value;
    long distance = 0;
    for (usz index = 0; index < count; index++) {
        long left = values[1 + index];
        long right = values[1 + count + index];
        if (left < 0 || left > 255 || right < 0 || right > 255) return -1;
        if (left != right) distance++;
    }
    return distance;
}
