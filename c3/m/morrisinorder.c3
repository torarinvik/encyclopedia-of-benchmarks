module morrisinorder;

const usz MAX_NODE_COUNT = 63;
const usz MAX_PARSEABLE_INPUT_LENGTH = 65;

fn void store_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

// Bounded Morris inorder traversal over a complete level-order tree.
fn long morrisinorder(long* values, usz length, char* output, usz capacity)
    @export("morrisinorder") {
    if (values == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long raw_count = values[0];
    if (raw_count < 0 || raw_count > (long)MAX_NODE_COUNT) return -1;
    usz count = (usz)raw_count;
    if (length != count + 1) return -1;
    for (usz index = 0; index < count; index += 1)
        if (values[index + 1] < -2147483648L || values[index + 1] > 2147483647L) return -1;

    usz byte_count = 4 * count;
    if (output == null || capacity < byte_count) return -2;

    int[63] left;
    int[63] right;
    for (usz index = 0; index < count; index += 1) {
        usz left_index = 2 * index + 1;
        usz right_index = 2 * index + 2;
        left[index] = left_index < count ? (int)left_index : -1;
        right[index] = right_index < count ? (int)right_index : -1;
    }

    int current = count == 0 ? -1 : 0;
    usz written = 0;
    while (current >= 0) {
        if (left[current] < 0) {
            store_i32_le(output, 4 * written, (int)values[1 + (usz)current]);
            written += 1;
            current = right[current];
        } else {
            int predecessor = left[current];
            while (right[predecessor] >= 0 && right[predecessor] != current)
                predecessor = right[predecessor];
            if (right[predecessor] < 0) {
                right[predecessor] = current;
                current = left[current];
            } else {
                right[predecessor] = -1;
                store_i32_le(output, 4 * written, (int)values[1 + (usz)current]);
                written += 1;
                current = right[current];
            }
        }
    }
    return (long)byte_count;
}
