/// Return the final term of a bounded N-bonacci sequence.
export fn n_bonacci(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const order_value = values[0];
    const count_value = values[1];
    if (order_value < 1 or count_value <= order_value or count_value > 64) return -1;
    const order: usize = @intCast(order_value);
    const count: usize = @intCast(count_value);
    var terms: [64]i64 = @splat(0);
    terms[order - 1] = 1;
    terms[order] = 1;
    for (order + 1..count) |index| {
        terms[index] = 2 * terms[index - 1] - terms[index - 1 - order];
    }
    return terms[count - 1];
}
