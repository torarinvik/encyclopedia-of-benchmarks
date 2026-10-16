/// Simple iterative modular inverse for bounded coprime positive inputs.
fn gcd_u64(left_input: u64, right_input: u64) u64 {
    var left = left_input;
    var right = right_input;
    while (right != 0) {
        const remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

export fn modular_inverse_simple(x_input: i64, y_input: i64) i64 {
    if (x_input < 1 or x_input > 999 or y_input < 2 or y_input > 1000) return -1;
    const x: u64 = @intCast(x_input);
    const y: u64 = @intCast(y_input);
    if (gcd_u64(x, y) != 1) return -1;

    var auxiliary: u64 = 0;
    var iteration: u64 = 0;
    while (true) {
        auxiliary = y * iteration + 1;
        iteration += 1;
        if (auxiliary % x == 0) break;
    }
    return @intCast(auxiliary / x);
}
