module median_search2;

const usz MAX_NODES = 128;
const usz MAX_INPUT_LENGTH = 129;

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long median_search2(long* input, usz length, char* output, usz capacity)
        @export("median_search2") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 128) return -1;
    usz count = (usz)input[0];
    if (length != count + 1) return -1;
    for (usz i = 0; i < count; i += 1)
        if (input[i + 1] < -2147483648 || input[i + 1] > 2147483647) return -1;

    int[128] next = zeroed;
    for (usz i = 0; i < count; i += 1)
        next[i] = if (i + 1 < count) then (int)(i + 1) else -1;
    int found = 0, median_index = -1;
    if (count > 0) {
        int slow = 0, fast = 0;
        while (next[(usz)fast] >= 0 && next[(usz)next[(usz)fast]] >= 0) {
            slow = next[(usz)slow];
            fast = next[(usz)next[(usz)fast]];
        }
        median_index = if (next[(usz)fast] >= 0) then next[(usz)slow] else slow;
        found = 1;
    }
    if (output == null || capacity < 8) return -2;
    char[8] buffer;
    put_i32_le(&buffer[0], 0, found);
    put_i32_le(&buffer[0], 4, median_index);
    for (usz i = 0; i < 8; i += 1) output[i] = buffer[i];
    return 8;
}
