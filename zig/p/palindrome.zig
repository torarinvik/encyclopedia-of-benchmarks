/// Check whether an exact ASCII string is a palindrome.
export fn palindrome(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 127) return -1;
    }
    for (0..length / 2) |left| {
        if (values[left] != values[length - 1 - left]) return 0;
    }
    return 1;
}
