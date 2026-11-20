export fn random_permutation_cycle_cap_count(input_opt: ?[*]const i64, input_length: usize) i64 {
    if (input_opt == null or input_length != 2) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const cap_value = input[1];
    if (n_value < 1 or n_value > 20 or cap_value < 1 or cap_value > n_value) return -1;

    const n: usize = @intCast(n_value);
    const cap: usize = @intCast(cap_value);
    var counts: [21]i64 = @splat(0);
    counts[0] = 1;
    for (1..(n + 1)) |size| {
        var total: i64 = 0;
        var cycle_choices: i64 = 1;
        const limit = if (size < cap) size else cap;
        for (1..(limit + 1)) |cycle_length| {
            if (cycle_length > 1) {
                cycle_choices *= @intCast(size - cycle_length + 1);
            }
            total += cycle_choices * counts[size - cycle_length];
        }
        counts[size] = total;
    }
    return counts[n];
}
