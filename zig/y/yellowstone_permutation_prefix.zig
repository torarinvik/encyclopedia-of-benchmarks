const MAX_N: i64 = 64;
const MIN_CAP: i64 = 3;
const MAX_CAP: i64 = 256;
const MAX_PARSEABLE_LENGTH: usize = 3;

fn gcdPositive(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn constructTerm(requested: i64, candidate_cap: i64) i64 {
    var terms: [64]i64 = @splat(0);
    var used: [257]bool = @splat(false);
    terms[0] = 1;
    terms[1] = 2;
    terms[2] = 3;
    if (requested <= 3) return terms[@intCast(requested - 1)];
    used[1] = true;
    used[2] = true;
    used[3] = true;

    var term_count: usize = 3;
    while (term_count < @as(usize, @intCast(requested))) {
        const two_back = terms[term_count - 2];
        const previous = terms[term_count - 1];
        var candidate: i64 = 1;
        while (candidate <= candidate_cap) {
            if (!used[@intCast(candidate)]
                and gcdPositive(candidate, two_back) > 1
                and gcdPositive(candidate, previous) == 1)
            {
                break;
            }
            candidate += 1;
        }
        if (candidate > candidate_cap) return -1;
        terms[term_count] = candidate;
        used[@intCast(candidate)] = true;
        term_count += 1;
    }
    return terms[@intCast(requested - 1)];
}

export fn yellowstone_permutation_prefix(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 2) return -1;
    const requested = input[0];
    const candidate_cap = input[1];
    if (requested < 1 or requested > MAX_N or candidate_cap < MIN_CAP or candidate_cap > MAX_CAP) return -1;
    return constructTerm(requested, candidate_cap);
}
