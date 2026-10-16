module two_pointers_pair_exists;

fn long two_pointers_pair_exists(long* input, usz length) @export("two_pointers_pair_exists") {
    if (input == null || length < 2 || length > 258) return -1;
    long target = input[0], n = input[1];
    if (n < 0 || n > 256 || length != 2 + (usz)n || target < -2000000 || target > 2000000) return -1;
    for (usz i = 0; i < (usz)n; i++) {
        long value = input[2 + i];
        if (value < -1000000 || value > 1000000) return -1;
        if (i > 0 && input[1 + i] > value) return -1;
    }
    if (n < 2) return 0;
    usz left = 0, right = (usz)n - 1;
    while (left < right) {
        long sum = input[2 + left] + input[2 + right];
        if (sum == target) return 1;
        if (sum < target) left++;
        else right--;
    }
    return 0;
}
