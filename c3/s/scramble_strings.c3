module scramble_strings;

const usz MAX_LENGTH = 8;
const usz MAX_PARSEABLE_INPUT_LENGTH = 2 * MAX_LENGTH + 3;
const usz MEMO_SIZE = 9 * 9 * 9;

fn long scramble_rec(long* values, usz base1, usz base2, usz start1, usz start2, usz span, long* memo) {
    usz slot = (start1 * 9 + start2) * 9 + span;
    if (memo[slot] >= 0) return memo[slot];

    bool same = true;
    for (usz offset = 0; offset < span; offset++)
        if (values[base1 + start1 + offset] != values[base2 + start2 + offset]) {
            same = false;
            break;
        }
    if (same) {
        memo[slot] = 1;
        return 1;
    }

    long[26] counts;
    for (usz index = 0; index < 26; index++) counts[index] = 0;
    for (usz offset = 0; offset < span; offset++) {
        usz first_bucket = (values[base1 + start1 + offset] - 'a').usz();
        usz second_bucket = (values[base2 + start2 + offset] - 'a').usz();
        counts[first_bucket]++;
        counts[second_bucket]--;
    }
    for (usz index = 0; index < 26; index++)
        if (counts[index] != 0) {
            memo[slot] = 0;
            return 0;
        }

    for (usz split = 1; split < span; split++) {
        if (scramble_rec(values, base1, base2, start1, start2, split, memo) != 0 &&
            scramble_rec(values, base1, base2, start1 + split, start2 + split, span - split, memo) != 0) {
            memo[slot] = 1;
            return 1;
        }
        if (scramble_rec(values, base1, base2, start1, start2 + span - split, split, memo) != 0 &&
            scramble_rec(values, base1, base2, start1 + split, start2, span - split, memo) != 0) {
            memo[slot] = 1;
            return 1;
        }
    }
    memo[slot] = 0;
    return 0;
}

fn long scramble_strings(long* values, usz length) @export("scramble_strings") {
    if (values == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long n_value = values[0];
    if (n_value < 0 || n_value > MAX_LENGTH) return -1;
    usz n = n_value.usz();
    if (length != 2 * n + 1) return -1;
    for (usz index = 1; index < length; index++)
        if (values[index] < 'a' || values[index] > 'z') return -1;

    long[MEMO_SIZE] memo;
    for (usz index = 0; index < MEMO_SIZE; index++) memo[index] = -1;
    return scramble_rec(values, 1, 1 + n, 0, 0, n, &memo[0]);
}
