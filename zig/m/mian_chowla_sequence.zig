const MAX_N: i64 = 30;
const MAX_PARSEABLE_LENGTH: usize = 2;
const MAX_SUMS: usize = 465;

export fn mian_chowla_sequence(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const requested = input[0];
    if (length != 1 or requested < 1 or requested > MAX_N) return -1;

    var terms: [30]i64 = @splat(0);
    var used_sums: [MAX_SUMS]i64 = @splat(0);
    var term_count: usize = 1;
    var sum_count: usize = 1;
    terms[0] = 1;
    used_sums[0] = 2;

    while (term_count < @as(usize, @intCast(requested))) {
        var candidate = terms[term_count - 1] + 1;
        while (true) {
            var valid = true;
            for (0..term_count) |term| {
                const sum = candidate + terms[term];
                for (0..sum_count) |old| {
                    if (used_sums[old] == sum) {
                        valid = false;
                        break;
                    }
                }
                if (!valid) break;
            }
            if (valid) {
                const doubled = 2 * candidate;
                for (0..sum_count) |old| {
                    if (used_sums[old] == doubled) {
                        valid = false;
                        break;
                    }
                }
            }
            if (valid) break;
            candidate += 1;
        }

        for (0..term_count) |term| {
            used_sums[sum_count] = candidate + terms[term];
            sum_count += 1;
        }
        used_sums[sum_count] = 2 * candidate;
        sum_count += 1;
        terms[term_count] = candidate;
        term_count += 1;
    }
    return terms[@intCast(requested - 1)];
}
