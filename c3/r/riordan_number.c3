module riordan_number;

const usz MAX_PARSEABLE_LENGTH = 2;
const long MAX_N = 30;

fn long riordan_number_value(long n) {
    long[31] values;
    for (int i = 0; i <= 30; i++) values[i] = 0;
    values[0] = 1;
    for (long size = 2; size <= n; size++) {
        values[size] = (size - 1) * (2 * values[size - 1] + 3 * values[size - 2])
                       / (size + 1);
    }
    return values[n];
}

fn long riordan_number(long* input, usz length) @export("riordan_number") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 0 || input[0] > MAX_N) return -1;
    return riordan_number_value(input[0]);
}
