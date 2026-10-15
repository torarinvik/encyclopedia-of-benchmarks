/// Match the product's decimal digits against the combined factor digits.
fn decimal_length(value_input: u64) u32 {
    var value = value_input;
    var length: u32 = 0;
    while (true) {
        length += 1;
        value /= 10;
        if (value == 0) break;
    }
    return length;
}

export fn vampire_number(left_input: u64, right_input: u64) i64 {
    if (left_input < 1 or left_input > 9999 or right_input < 1 or right_input > 9999) return -1;
    if (decimal_length(left_input) != decimal_length(right_input)) return 0;
    var counts = [_]i32{0} ** 10;
    var product = left_input * right_input;
    var left = left_input;
    var right = right_input;
    while (product != 0) {
        counts[@intCast(product % 10)] += 1;
        product /= 10;
    }
    while (left != 0) {
        counts[@intCast(left % 10)] -= 1;
        left /= 10;
    }
    while (right != 0) {
        counts[@intCast(right % 10)] -= 1;
        right /= 10;
    }
    for (counts) |count| if (count != 0) return 0;
    return 1;
}
