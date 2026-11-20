const max_n: usize = 8;
const max_candidate: usize = 40_320;
const max_parseable_length: usize = 2;

fn gcdI64(left: i64, right: i64) i64 {
    var a = left;
    var b = right;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

export fn ekg_sequence(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > max_parseable_length) return -1;
    const values = input.?[0..1];
    const requested = values[0];
    if (length != 1 or requested < 1 or requested > @as(i64, @intCast(max_n))) return -1;

    var terms: [max_n]i64 = @splat(0);
    var used: [max_candidate + 1]u8 = @splat(0);
    terms[0] = 1;
    used[1] = 1;
    var term_count: usize = 1;
    if (requested >= 2) {
        terms[1] = 2;
        used[2] = 1;
        term_count = 2;
    }

    while (term_count < @as(usize, @intCast(requested))) {
        const position: i64 = @intCast(term_count + 1);
        const previous = terms[term_count - 1];
        const search_bound = previous * position;
        var candidate: i64 = 1;
        while (candidate <= search_bound) : (candidate += 1) {
            if (used[@intCast(candidate)] == 0 and gcdI64(previous, candidate) > 1) break;
        }
        if (candidate > search_bound) return -1;
        terms[term_count] = candidate;
        used[@intCast(candidate)] = 1;
        term_count += 1;
    }

    const output_bytes = @as(usize, @intCast(requested)) * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    const bytes = output.?[0..output_bytes];
    for (0..term_count) |index| {
        const bits: u64 = @bitCast(terms[index]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            bytes[index * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
