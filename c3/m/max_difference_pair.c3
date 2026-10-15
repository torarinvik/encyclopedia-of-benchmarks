module max_difference_pair;
const usz MAX_N = 128;
struct Pair { long small, big; }
fn Pair solve(long* values, usz n) {
    if (n == 1) return Pair{values[0], values[0]};
    usz left_n = n / 2;
    Pair left = solve(values, left_n), right = solve(values + left_n, n - left_n);
    long min_left = values[0], max_right = values[left_n];
    for (usz i = 1; i < left_n; i++) if (values[i] < min_left) min_left = values[i];
    for (usz i = left_n + 1; i < n; i++) if (values[i] > max_right) max_right = values[i];
    long cross = max_right - min_left, right_diff = right.big - right.small, left_diff = left.big - left.small;
    if (right_diff > cross && right_diff > left_diff) return right;
    if (left_diff > cross) return left;
    return Pair{min_left, max_right};
}
fn void put_le(long value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz b = 0; b < 8; b++) { output[offset + b] = (char)(bits & 255); bits >>= 8; }
}
fn long max_difference_pair(long* input, usz length, char* output, usz capacity) @export("max_difference_pair") {
    if (input == null || length < 2 || input[0] < 1 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0]; if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < -1000000 || input[i + 1] > 1000000) return -1;
    if (capacity < 16 || output == null) return -2;
    Pair result = solve(input + 1, n);
    put_le(result.small, output, 0); put_le(result.big, output, 8);
    return 16;
}
