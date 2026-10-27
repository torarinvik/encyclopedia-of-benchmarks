const MAX_N: usize = 6;
const MAX_INPUT: usize = 73;
const MAX_OUTPUT_BYTES: usize = 104;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn weak_stable_matching_ties_incomplete(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    if (n_raw < 1 or n_raw > @as(i64, MAX_N)) return -1;
    const n: usize = @intCast(n_raw);
    const side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;
    var men_rank: [MAX_N][MAX_N]i64 = @splat(@splat(0));
    var women_rank: [MAX_N][MAX_N]i64 = @splat(@splat(0));
    var choices: [MAX_N][MAX_N]usize = @splat(@splat(0));
    var choice_count: [MAX_N]usize = @splat(0);
    for (0..n) |man| {
        for (0..n) |woman| {
            const rank = input[1 + man * n + woman];
            if (rank < 0 or rank > n_raw) return -1;
            men_rank[man][woman] = rank;
        }
    }
    for (0..n) |woman| {
        for (0..n) |man| {
            const rank = input[1 + side_size + woman * n + man];
            if (rank < 0 or rank > n_raw or ((rank > 0) != (men_rank[man][woman] > 0))) return -1;
            women_rank[woman][man] = rank;
        }
    }
    for (0..n) |man| {
        for (0..n) |woman| {
            if (men_rank[man][woman] == 0) continue;
            var at = choice_count[man];
            while (at > 0) {
                const prior = choices[man][at - 1];
                if (men_rank[man][prior] < men_rank[man][woman] or
                        (men_rank[man][prior] == men_rank[man][woman] and prior < woman)) break;
                choices[man][at] = prior;
                at -= 1;
            }
            choices[man][at] = woman;
            choice_count[man] += 1;
        }
    }
    var man_partner: [MAX_N]i32 = @splat(-1);
    var woman_partner: [MAX_N]i32 = @splat(-1);
    var next_choice: [MAX_N]usize = @splat(0);
    while (true) {
        var man = MAX_N;
        for (0..n) |candidate| {
            if (man_partner[candidate] < 0 and next_choice[candidate] < choice_count[candidate]) { man = candidate; break; }
        }
        if (man == MAX_N) break;
        const woman = choices[man][next_choice[man]];
        next_choice[man] += 1;
        const incumbent = woman_partner[woman];
        if (incumbent < 0 or women_rank[woman][man] < women_rank[woman][@intCast(incumbent)] or
                (women_rank[woman][man] == women_rank[woman][@intCast(incumbent)] and man < @as(usize, @intCast(incumbent)))) {
            woman_partner[woman] = @intCast(man);
            man_partner[man] = @intCast(woman);
            if (incumbent >= 0) man_partner[@intCast(incumbent)] = -1;
        }
    }
    var words: [1 + 2 * MAX_N]i64 = @splat(0);
    var pairs: usize = 0;
    for (0..n) |man| {
        if (man_partner[man] >= 0) {
            words[1 + 2 * pairs] = @intCast(man);
            words[2 + 2 * pairs] = man_partner[man];
            pairs += 1;
        }
    }
    words[0] = @intCast(pairs);
    const output_bytes = 8 * (1 + 2 * pairs);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..1 + 2 * pairs) |word| store_i64_le(&staged, 8 * word, words[word]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
