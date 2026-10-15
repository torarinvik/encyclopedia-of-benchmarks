/// Add two signed i32 operands with XOR and shifted carry in a 64-bit word.
fn bitwiseAdd(a: i64, b: i64) i64 {
    var left: u64 = @bitCast(a);
    var right: u64 = @bitCast(b);
    while (right != 0) {
        const partial = left ^ right;
        right = (left & right) << 1;
        left = partial;
    }
    return @bitCast(left);
}

export fn sum_of_two_integers(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length != 2) return -1;
    const input = values.?[0..length];
    const a = input[0];
    const b = input[1];
    if (a < -2147483648 or a > 2147483647 or b < -2147483648 or b > 2147483647) return -1;
    return bitwiseAdd(a, b);
}
