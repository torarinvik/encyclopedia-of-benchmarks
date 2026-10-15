module huffman_weighted_cost;

const MAX_SYMBOLS = 26;
const MAX_TOTAL_FREQUENCY = 2147483647;

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long huffman_weighted_cost(long* values, usz length, char* output, usz capacity)
        @export("huffman_weighted_cost") {
    if (values == null || length < 1 || length > 53) return -1;
    long raw_count = values[0];
    if (raw_count < 2 || raw_count > MAX_SYMBOLS || length != 1 + 2 * (usz)raw_count) return -1;
    usz count = (usz)raw_count;

    bool[26] seen = zeroed;
    bool[26] active = zeroed;
    long[26] weights;
    long total = 0;
    for (usz index = 0; index < count; index += 1) {
        long symbol = values[1 + 2 * index];
        long frequency = values[2 + 2 * index];
        if (symbol < 97 || symbol > 122 || frequency < 1 || frequency > MAX_TOTAL_FREQUENCY) return -1;
        usz letter = (usz)(symbol - 97);
        if (seen[letter] || total > MAX_TOTAL_FREQUENCY - frequency) return -1;
        seen[letter] = true;
        active[index] = true;
        weights[index] = frequency;
        total += frequency;
    }

    usz remaining = count;
    long cost = 0;
    while (remaining > 1) {
        usz first = 26;
        usz second = 26;
        for (usz index = 0; index < count; index += 1) {
            if (!active[index]) continue;
            if (first == 26 || weights[index] < weights[first]) {
                second = first;
                first = index;
            } else if (second == 26 || weights[index] < weights[second]) {
                second = index;
            }
        }
        weights[first] += weights[second];
        active[second] = false;
        cost += weights[first];
        remaining -= 1;
    }

    if (output == null || capacity < 8) return -2;
    store_i64_le(output, cost);
    return cost;
}
