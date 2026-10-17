module recursive_linear_search;

const usz MAX_N = 64;
const long I32_MIN_VALUE = -2147483648;
const long I32_MAX_VALUE = 2147483647;

fn int search_recursive(int* items, int left, int right, int target) {
    if (left > right) return -1;
    if (items[left] == target) return left;
    if (items[right] == target) return right;
    return search_recursive(items, left + 1, right - 1, target);
}

fn long recursive_linear_search(long* input, usz length) @export("recursive_linear_search") {
    if (input == null || length < 4 || length > 66) return -1;
    if (input[0] < 2 || input[0] > (long)MAX_N || length != (usz)input[0] + 2) return -1;
    if (input[1] < I32_MIN_VALUE || input[1] > I32_MAX_VALUE) return -1;
    usz n = (usz)input[0];
    int[MAX_N] items;
    for (usz i = 0; i < n; i++) {
        if (input[i + 2] < I32_MIN_VALUE || input[i + 2] > I32_MAX_VALUE) return -1;
        items[i] = (int)input[i + 2];
        for (usz j = 0; j < i; j++) if (items[j] == items[i]) return -1;
    }
    return (long)search_recursive(items, 0, (int)n - 1, (int)input[1]);
}
