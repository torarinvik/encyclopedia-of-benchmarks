module decimal_to_octal_recursion;

fn long encode_octal_digits(long value) {
    if (value == 0) return 0;
    return encode_octal_digits(value / 8) * 10 + value % 8;
}

// Return decimal-coded octal digits, or -1 outside 0..295600127.
fn long decimal_to_octal_recursion(long value) @export("decimal_to_octal_recursion") {
    if (value < 0 || value > 295600127) return -1;
    return encode_octal_digits(value);
}
