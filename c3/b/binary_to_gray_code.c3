module binary_to_gray_code;

// Convert a nonnegative integer to its binary-reflected Gray code.
fn long binary_to_gray_code(long value) @export("binary_to_gray_code") {
    if (value < 0) return -1;
    return value ^ (value >> 1);
}
