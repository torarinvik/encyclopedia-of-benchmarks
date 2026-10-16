module combination_sum;

const MAX_CANDIDATES = 8;
const MAX_TARGET = 20;
const MAX_PACKED_WORDS = 4096;

fn void enumerate(long* candidates, usz count, usz start, long remaining, usz depth,
                  long* path, long* packed, usz* used) {
    if (remaining == 0) {
        packed[*used] = (long)depth;
        *used += 1;
        for (usz i = 0; i < depth; i++) {
            packed[*used] = path[i];
            *used += 1;
        }
        packed[0] += 1;
        return;
    }
    for (usz i = start; i < count; i++) {
        long candidate = candidates[i];
        if (candidate > remaining) break;
        path[depth] = candidate;
        enumerate(candidates, count, i, remaining - candidate, depth + 1, path, packed, used);
    }
}

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long combination_sum(long* input, usz length, char* output, usz capacity)
    @export("combination_sum") {
    if (input == null || length < 3) return -1;
    long count_value = input[0];
    long target = input[1];
    if (count_value < 1 || count_value > MAX_CANDIDATES || target < 0 || target > MAX_TARGET) return -1;
    usz count = (usz)count_value;
    if (length != count + 2) return -1;
    for (usz i = 0; i < count; i++) {
        long candidate = input[i + 2];
        if (candidate < 1 || candidate > 24 || (i > 0 && input[i + 1] >= candidate)) return -1;
    }

    long[MAX_TARGET] path;
    long[MAX_PACKED_WORDS] packed;
    usz used = 1;
    packed[0] = 0;
    enumerate(&input[2], count, 0, target, 0, &path[0], &packed[0], &used);
    usz required = used * 8;
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < used; i++) put_i64(output, i * 8, packed[i]);
    return (long)required;
}
