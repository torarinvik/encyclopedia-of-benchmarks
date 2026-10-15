module find_max_recursion;

const MAX_LENGTH = 256;

fn long find_max_range(long* values, usz low, usz high) {
    if (low == high) return values[low];
    usz middle = low + (high - low) / 2;
    long left = find_max_range(values, low, middle);
    long right = find_max_range(values, middle + 1, high);
    return left >= right ? left : right;
}

fn long find_max_recursion(long* values, usz length) @export("find_max_recursion") {
    if (values == null || length == 0 || length > MAX_LENGTH) return -1;
    for (usz i = 0; i < length; i++) if (values[i] < -2147483648 || values[i] > 2147483647) return -1;
    return find_max_range(values, 0, length - 1);
}
