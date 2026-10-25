const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_N;
const MAX_VALUE: i64 = 1_000_000;

export fn tsvc_s4115_indexed_gather_product_sum(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 1 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + 3 * n) return -1;
    for (0..n) |i| {
        const index = values[1 + i];
        const a_value = values[1 + n + i];
        const b_value = values[1 + 2 * n + i];
        if (index < 0 or index >= n_raw) return -1;
        if (a_value < 0 or a_value > MAX_VALUE or b_value < 0 or b_value > MAX_VALUE) return -1;
    }

    var sum: i64 = 0;
    for (0..n) |i| {
        const index: usize = @intCast(values[1 + i]);
        sum += values[1 + n + i] * values[1 + 2 * n + index];
    }
    return sum;
}
