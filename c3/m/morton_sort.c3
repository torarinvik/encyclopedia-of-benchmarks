module morton_sort;

fn uint spread_16(uint value) {
    value = (value | (value << 8)) & 0x00ff00ff;
    value = (value | (value << 4)) & 0x0f0f0f0f;
    value = (value | (value << 2)) & 0x33333333;
    return (value | (value << 1)) & 0x55555555;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long morton_sort(long* input, usz length, char* output, usz capacity) @export("morton_sort") {
    if (input == null || length < 3 || length > 513 || input[0] < 1 || input[0] > 256) return -1;
    usz count = (usz)input[0];
    if (length != 1 + 2 * count) return -1;
    uint[256] keys;
    usz[256] order;
    for (usz index = 0; index < count; index += 1) {
        long x = input[1 + 2 * index], y = input[2 + 2 * index];
        if (x < 0 || x > 65535 || y < 0 || y > 65535) return -1;
        keys[index] = spread_16((uint)x) | (spread_16((uint)y) << 1);
        order[index] = index;
    }
    usz bytes = count * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz index = 1; index < count; index += 1) {
        usz current = order[index];
        usz position = index;
        while (position > 0 && (keys[order[position - 1]] > keys[current] ||
               (keys[order[position - 1]] == keys[current] && order[position - 1] > current))) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }
    for (usz index = 0; index < count; index += 1) store_i64_le(output, index * 8, (long)order[index]);
    return (long)bytes;
}
