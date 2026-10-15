const INVALID_RESULT: i64 = -9223372036854775807 - 1;

pub export fn max_product_of_three(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or input[0] < 3 or input[0] > 128 or length != @as(usize, @intCast(input[0])) + 1) return INVALID_RESULT;
    const n: usize = @intCast(input[0]);
    for (0..n) |i| if (input[i + 1] < -1000 or input[i + 1] > 1000) return INVALID_RESULT;
    var max1 = input[1]; var max2: i64 = -1001; var max3: i64 = -1001;
    var min1 = input[1]; var min2: i64 = 1001;
    for (1..n) |i| {
        const value = input[i + 1];
        if (value > max1) { max3 = max2; max2 = max1; max1 = value; }
        else if (value > max2) { max3 = max2; max2 = value; }
        else if (value > max3) { max3 = value; }
        if (value < min1) { min2 = min1; min1 = value; }
        else if (value < min2) { min2 = value; }
    }
    const product1 = max1 * max2 * max3;
    const product2 = max1 * min1 * min2;
    return @max(product1, product2);
}
