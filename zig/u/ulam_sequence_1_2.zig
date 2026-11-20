const MAX_N: i64 = 14;
const MAX_CANDIDATE: i64 = 64;
const MAX_PARSEABLE_LENGTH: usize = 2;

export fn ulam_sequence_1_2(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const requested = input[0];
    if (length != 1 or requested < 1 or requested > MAX_N) return -1;

    var terms: [14]i64 = @splat(0);
    var representations: [75]i64 = @splat(0);
    terms[0] = 1;
    terms[1] = 2;
    representations[3] = 1;
    var term_count: usize = 2;

    while (term_count < @as(usize, @intCast(requested))) {
        var candidate = terms[term_count - 1] + 1;
        while (candidate <= MAX_CANDIDATE and representations[@intCast(candidate)] != 1)
            candidate += 1;
        if (candidate > MAX_CANDIDATE) return -1;
        for (0..term_count) |old| {
            const sum: usize = @intCast(candidate + terms[old]);
            if (representations[sum] < 2) representations[sum] += 1;
        }
        terms[term_count] = candidate;
        term_count += 1;
    }
    return terms[@intCast(requested - 1)];
}
