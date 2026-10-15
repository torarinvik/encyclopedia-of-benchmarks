export fn number_of_subarrays_with_odd_sum(values: [*]const i64, length: usize) i64 {
    const modulus: i64 = 1_000_000_007;
    if (length > 100_000) return -1;
    var even_prefixes: i64 = 1;
    var odd_prefixes: i64 = 0;
    var result: i64 = 0;
    var parity: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < -2147483648 or value > 2147483647) return -1;
        if (@rem(value, 2) != 0) parity = 1 - parity;
        if (parity == 0) {
            result = @rem(result + odd_prefixes, modulus);
            even_prefixes += 1;
        } else {
            result = @rem(result + even_prefixes, modulus);
            odd_prefixes += 1;
        }
    }
    return result;
}
