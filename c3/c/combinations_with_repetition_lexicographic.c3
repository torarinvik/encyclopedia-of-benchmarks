module combinations_with_repetition_lexicographic;

fn usz multiset_count(usz n, usz r) {
    if (r == 0) return 1;
    if (n == 0) return 0;
    usz top = n + r - 1;
    usz result = 1;
    for (usz index = 1; index <= r; index++) result = result * (top - r + index) / index;
    return result;
}

fn long combinations_with_repetition_lexicographic(long* input, usz length,
        char* output, usz capacity) @export("combinations_with_repetition_lexicographic") {
    if (input == null || length != 2) return -1;
    if (input[0] < 0 || input[0] > 4 || input[1] < 0 || input[1] > 4) return -1;
    usz n = (usz)input[0];
    usz r = (usz)input[1];
    usz count = multiset_count(n, r);
    usz byte_count = 2 + count * r;
    if (output == null || capacity < byte_count) return -2;

    output[0] = (char)(count & 255);
    output[1] = (char)((count >> 8) & 255);
    char[4] current = {0};
    for (usz ordinal = 0; ordinal < count; ordinal++) {
        for (usz position = 0; position < r; position++)
            output[2 + ordinal * r + position] = current[position];
        if (ordinal + 1 == count || r == 0) continue;
        usz position = r;
        while ((usz)current[position - 1] == n - 1) position--;
        position--;
        current[position]++;
        for (usz suffix = position + 1; suffix < r; suffix++) current[suffix] = current[position];
    }
    return (long)byte_count;
}
