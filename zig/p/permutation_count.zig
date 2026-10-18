export fn permutation_count(input: ?[*]const i64, input_length: usize) i64 {
    if (input == null or input_length != 2) return -1;
    const values = input.?;
    const n = values[0];
    const r = values[1];
    if (n < 0 or n > 18 or r < 0 or r > 18) return -1;
    var result: i64 = 1;
    if (r > n) {
        var factor: i64 = 2;
        while (factor <= n) : (factor += 1) result *= factor;
    } else {
        var i: i64 = 0;
        while (i < r) : (i += 1) result *= n - i;
    }
    return result;
}
