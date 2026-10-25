const MAX_N: usize = 48;
const MAX_INPUT_LENGTH: usize = 1 + MAX_N;
const MAX_VALUE: i64 = 2;

export fn tsvc_s312_array_product(input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const n_raw = input[0];
    if (n_raw < 0 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + n) return -1;

    var product: i64 = 1;
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < 0 or value > MAX_VALUE) return -1;
        product *= value;
    }
    return product;
}
