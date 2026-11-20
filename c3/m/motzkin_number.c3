module motzkin_number;

const usz MAX_PARSEABLE_LENGTH = 2;
const long MAX_N = 30;

fn long motzkin_number_value(long n) {
    long[31] values;
    for (int i = 0; i <= 30; i++) values[i] = 0;
    values[0] = 1;
    if (n >= 1) values[1] = 1;
    for (long size = 2; size <= n; size++) {
        long total = values[size - 1];
        for (long left = 0; left <= size - 2; left++)
            total += values[left] * values[size - 2 - left];
        values[size] = total;
    }
    return values[n];
}

fn long motzkin_number(long* input, usz length) @export("motzkin_number") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 0 || input[0] > MAX_N) return -1;
    return motzkin_number_value(input[0]);
}
