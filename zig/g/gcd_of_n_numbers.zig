/// Fold positive signed 32-bit values with Euclid's GCD algorithm.
export fn gcd_of_n_numbers(values: [*c]const i64, length: usize) i64 {
    if (length == 0 or length > 64) return -1;
    for (0..length) |index| {
        const value = values[index];
        if (value < 1 or value > 2147483647) return -1;
    }
    var result = values[0];
    for (1..length) |index| {
        if (result == 1) break;
        var left = result;
        var right = values[index];
        while (right != 0) {
            const remainder = @rem(left, right);
            left = right;
            right = remainder;
        }
        result = left;
    }
    return result;
}
