/// Multiply nonnegative operands with shift-and-add; inputs are at most 1e9.
export fn binary_multiplication(a: u64, b: u64) i64 {
    var multiplicand = a;
    var multiplier = b;
    var result: u64 = 0;
    while (multiplier > 0) {
        if ((multiplier & 1) != 0) {
            result += multiplicand;
        }
        multiplicand += multiplicand;
        multiplier >>= 1;
    }
    return @intCast(result);
}
