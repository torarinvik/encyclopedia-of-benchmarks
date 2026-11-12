const max_cases: usize = 4;
const max_vectors: usize = 8;
const max_bits: usize = 30;
const max_input_values: usize = 1 + max_cases * (2 + 2 * max_vectors) + 1;
const max_output_words: usize = max_cases * (1 + max_vectors);
const max_vector: i64 = 0x3fff_ffff;

fn insertIndependent(basis: *[max_bits]u32, value: u32) bool {
    var row = value;
    var bit: i32 = @intCast(max_bits - 1);
    while (bit >= 0) : (bit -= 1) {
        const index: usize = @intCast(bit);
        const mask = @as(u32, 1) << @intCast(bit);
        if ((row & mask) == 0) continue;
        if (basis[index] != 0) row ^= basis[index] else {
            basis[index] = row;
            return true;
        }
    }
    return false;
}

fn intersectionBasis(left: *const [max_vectors]u32, n: usize,
    right: *const [max_vectors]u32, m: usize, output: *[max_vectors]u32) usize {
    var right_basis = [_]u32{0} ** max_bits;
    var right_coeff = [_]u32{0} ** max_bits;
    for (0..m) |index| {
        var row = right[index];
        var coefficients = @as(u32, 1) << @intCast(index);
        var bit: i32 = @intCast(max_bits - 1);
        while (bit >= 0) : (bit -= 1) {
            const slot: usize = @intCast(bit);
            if (((row >> @intCast(bit)) & 1) == 0) continue;
            if (right_basis[slot] != 0) {
                row ^= right_basis[slot];
                coefficients ^= right_coeff[slot];
            } else {
                right_basis[slot] = row;
                right_coeff[slot] = coefficients;
                break;
            }
        }
    }

    var quotient_basis = [_]u32{0} ** max_bits;
    var quotient_left_coeff = [_]u32{0} ** max_bits;
    var quotient_right_coeff = [_]u32{0} ** max_bits;
    var intersection = [_]u32{0} ** max_vectors;
    var intersection_count: usize = 0;
    for (0..n) |index| {
        var row = left[index];
        var right_mask: u32 = 0;
        var bit: i32 = @intCast(max_bits - 1);
        while (bit >= 0) : (bit -= 1) {
            const slot: usize = @intCast(bit);
            if (((row >> @intCast(bit)) & 1) != 0 and right_basis[slot] != 0) {
                row ^= right_basis[slot];
                right_mask ^= right_coeff[slot];
            }
        }
        var left_mask = @as(u32, 1) << @intCast(index);
        bit = @intCast(max_bits - 1);
        while (bit >= 0) : (bit -= 1) {
            const slot: usize = @intCast(bit);
            if (((row >> @intCast(bit)) & 1) == 0) continue;
            if (quotient_basis[slot] != 0) {
                row ^= quotient_basis[slot];
                left_mask ^= quotient_left_coeff[slot];
                right_mask ^= quotient_right_coeff[slot];
            } else {
                quotient_basis[slot] = row;
                quotient_left_coeff[slot] = left_mask;
                quotient_right_coeff[slot] = right_mask;
                break;
            }
        }
        if (row == 0) {
            var common: u32 = 0;
            for (0..n) |source| {
                if (((left_mask >> @intCast(source)) & 1) != 0) common ^= left[source];
            }
            intersection[intersection_count] = common;
            intersection_count += 1;
        }
    }

    var rref = [_]u32{0} ** max_bits;
    for (0..intersection_count) |index| {
        var row = intersection[index];
        var bit: i32 = @intCast(max_bits - 1);
        while (bit >= 0) : (bit -= 1) {
            const slot: usize = @intCast(bit);
            if (((row >> @intCast(bit)) & 1) == 0) continue;
            if (rref[slot] != 0) row ^= rref[slot] else {
                rref[slot] = row;
                for (0..max_bits) |pivot| {
                    if (@as(i32, @intCast(pivot)) != bit and ((rref[pivot] >> @intCast(bit)) & 1) != 0)
                        rref[pivot] ^= row;
                }
                break;
            }
        }
    }
    var output_count: usize = 0;
    var bit: i32 = @intCast(max_bits - 1);
    while (bit >= 0) : (bit -= 1) {
        const slot: usize = @intCast(bit);
        if (rref[slot] != 0) {
            output[output_count] = rref[slot];
            output_count += 1;
        }
    }
    return output_count;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn intersection_of_f2_vector_spaces(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > max_input_values) return -1;
    const input = input_opt.?;
    const case_count_value = input[0];
    if (case_count_value < 1 or case_count_value > @as(i64, @intCast(max_cases))) return -1;
    const case_count: usize = @intCast(case_count_value);
    var staged = [_]i64{0} ** max_output_words;
    var used: usize = 0;
    var cursor: usize = 1;
    for (0..case_count) |_| {
        if (cursor >= length) return -1;
        const n_value = input[cursor];
        cursor += 1;
        if (n_value < 0 or n_value > @as(i64, @intCast(max_vectors))) return -1;
        const n: usize = @intCast(n_value);
        if (cursor + n > length) return -1;
        var left = [_]u32{0} ** max_vectors;
        var left_check = [_]u32{0} ** max_bits;
        for (0..n) |index| {
            const value = input[cursor];
            cursor += 1;
            if (value < 0 or value > max_vector or !insertIndependent(&left_check, @intCast(value))) return -1;
            left[index] = @intCast(value);
        }
        if (cursor >= length) return -1;
        const m_value = input[cursor];
        cursor += 1;
        if (m_value < 0 or m_value > @as(i64, @intCast(max_vectors))) return -1;
        const m: usize = @intCast(m_value);
        if (cursor + m > length) return -1;
        var right = [_]u32{0} ** max_vectors;
        var right_check = [_]u32{0} ** max_bits;
        for (0..m) |index| {
            const value = input[cursor];
            cursor += 1;
            if (value < 0 or value > max_vector or !insertIndependent(&right_check, @intCast(value))) return -1;
            right[index] = @intCast(value);
        }
        var basis = [_]u32{0} ** max_vectors;
        const dimension = intersectionBasis(&left, n, &right, m, &basis);
        staged[used] = @intCast(dimension);
        used += 1;
        for (0..dimension) |index| {
            staged[used] = @intCast(basis[index]);
            used += 1;
        }
    }
    if (cursor != length) return -1;
    const required = 8 * used;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..used) |index| storeI64Le(output, 8 * index, staged[index]);
    return @intCast(required);
}
