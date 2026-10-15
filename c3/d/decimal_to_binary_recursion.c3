module decimal_to_binary_recursion;

fn long encode_binary_digits(long value) {
    if (value == 0) return 0;
    return (value % 2) + 10 * encode_binary_digits(value / 2);
}

// Return decimal-coded binary digits, or -1 outside 0..1023.
fn long decimal_to_binary_recursion(long value) @export("decimal_to_binary_recursion") {
    if (value < 0 || value > 1023) return -1;
    return encode_binary_digits(value);
}
