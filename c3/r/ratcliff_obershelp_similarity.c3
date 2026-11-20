module ratcliff_obershelp_similarity;

const usz MAX_TEXT = 32;
const usz MAX_INPUT_LENGTH = 67;

fn long longest_match(long* input, usz first_base, usz second_base,
                      usz first_start, usz first_end, usz second_start,
                      usz second_end) {
    long[33] dp;
    for (usz i = 0; i < 33; i++) dp[i] = 0;
    usz best_length = 0, best_first = 0, best_second = 0;
    usz width = second_end - second_start;
    for (usz i = first_start; i < first_end; i++) {
        long diagonal = 0;
        for (usz column = 1; column <= width; column++) {
            long old = dp[column];
            usz j = second_start + column - 1;
            if (input[first_base + i] == input[second_base + j]) {
                usz current = (usz)diagonal + 1;
                dp[column] = (long)current;
                if (current > best_length) {
                    best_length = current;
                    best_first = i + 1 - current;
                    best_second = j + 1 - current;
                }
            } else dp[column] = 0;
            diagonal = old;
        }
    }
    return (long)(best_length * 4096 + best_first * 64 + best_second);
}

fn long matched_characters(long* input, usz first_base, usz second_base,
                           usz a0, usz a1, usz b0, usz b1) {
    if (a0 >= a1 || b0 >= b1) return 0;
    long packed = longest_match(input, first_base, second_base, a0, a1, b0, b1);
    usz block = (usz)(packed / 4096);
    if (block == 0) return 0;
    usz rest = (usz)(packed % 4096), a = rest / 64, b = rest % 64;
    return (long)block
        + matched_characters(input, first_base, second_base, a0, a, b0, b)
        + matched_characters(input, first_base, second_base, a + block, a1,
                             b + block, b1);
}

fn long ratcliff_obershelp_similarity(long* input, usz length)
    @export("ratcliff_obershelp_similarity") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long first_raw = input[0], second_raw = input[1];
    if (first_raw < 0 || first_raw > (long)MAX_TEXT
        || second_raw < 0 || second_raw > (long)MAX_TEXT) return -1;
    usz first_length = (usz)first_raw, second_length = (usz)second_raw;
    if (length != 2 + first_length + second_length) return -1;
    for (usz i = 0; i < first_length + second_length; i++)
        if (input[2 + i] < 1 || input[2 + i] > 127) return -1;
    if (first_length == 0 || second_length == 0) return 0;
    usz second_base = 2 + first_length;
    long common = matched_characters(input, 2, second_base, 0, first_length,
                                    0, second_length);
    return (200 * common) / (long)(first_length + second_length);
}
