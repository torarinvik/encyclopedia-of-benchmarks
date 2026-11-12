const modulus: i64 = 998_244_353;
const max_n: i64 = 16;

export fn stirling_number_of_the_second_kind(input_opt: ?[*]const i64,
    length: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const n_value = input_opt.?[0];
    if (n_value < 0 or n_value > max_n) return -1;
    const n: usize = @intCast(n_value);

    var row: [17]i64 = @splat(0);
    row[0] = 1;
    var current_n: usize = 1;
    while (current_n <= n) : (current_n += 1) {
        var k = current_n;
        while (k > 0) : (k -= 1) {
            row[k] = @rem(row[k - 1] + @as(i64, @intCast(k)) * row[k], modulus);
        }
        row[0] = 0;
    }

    var result: i64 = 0;
    for (0..n + 1) |k| {
        const next: i64 = @intCast(k + 1);
        const weight = next * next * next;
        result = @rem(result + weight * row[k], modulus);
    }
    return result;
}
