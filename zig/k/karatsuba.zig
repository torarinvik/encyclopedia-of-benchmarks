/// Multiply bounded nonnegative operands with a three-product decimal split.
fn karatsubaProduct(left: i64, right: i64) i64 {
    if (left < 10 or right < 10) return left * right;
    var largest = @max(left, right);
    var digits: usize = 1;
    while (largest >= 10) : (digits += 1) { largest /= 10; }
    var split: i64 = 1;
    for (0..digits / 2) |_| { split *= 10; }
    const left_high = @divTrunc(left, split);
    const left_low = @rem(left, split);
    const right_high = @divTrunc(right, split);
    const right_low = @rem(right, split);
    const low_product = karatsubaProduct(left_low, right_low);
    const high_product = karatsubaProduct(left_high, right_high);
    const sum_product = karatsubaProduct(left_high + left_low, right_high + right_low);
    return high_product * split * split + (sum_product - high_product - low_product) * split + low_product;
}

export fn karatsuba(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?;
    const left = values[0];
    const right = values[1];
    if (left < 0 or left > 1000000 or right < 0 or right > 1000000) return -1;
    return karatsubaProduct(left, right);
}
