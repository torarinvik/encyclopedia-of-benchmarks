module string_heap_sort;

const usz MAX_KEYS = 64;
const usz KEY_WIDTH = 4;
const usz MAX_INPUT_LENGTH = 1 + MAX_KEYS * KEY_WIDTH;

fn void sift_down(uint* keys, usz root, usz end) {
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && keys[child] < keys[child + 1]) child += 1;
        if (keys[root] >= keys[child]) break;
        uint t = keys[root]; keys[root] = keys[child]; keys[child] = t;
        root = child;
    }
}

fn long string_heap_sort(long* values, usz length, char* output, usz output_capacity)
    @export("string_heap_sort") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long raw_count = values[0];
    if (raw_count < 0 || raw_count > (long)MAX_KEYS || length != 1 + KEY_WIDTH * (usz)raw_count) return -1;
    usz count = (usz)raw_count;
    uint[MAX_KEYS] keys;
    for (usz i = 0; i < count; i += 1) {
        uint key = 0;
        for (usz b = 0; b < KEY_WIDTH; b += 1) {
            long byte = values[1 + KEY_WIDTH * i + b];
            if (byte < 0 || byte > 127) return -1;
            key = (key << 8) | (uint)byte;
        }
        keys[i] = key;
    }
    for (usz start = count / 2; start > 0;) { start -= 1; sift_down(keys, start, count); }
    for (usz end = count; end > 1;) {
        end -= 1; uint t = keys[0]; keys[0] = keys[end]; keys[end] = t;
        sift_down(keys, 0, end);
    }
    usz bytes = count * KEY_WIDTH;
    if (output == null || output_capacity < bytes) return -2;
    for (usz i = 0; i < count; i += 1)
        for (usz b = 0; b < KEY_WIDTH; b += 1)
            output[i * KEY_WIDTH + b] = (char)((keys[i] >> (24 - 8 * b)) & 255);
    return (long)bytes;
}
