const max_side: usize = 12;
const max_cells: usize = max_side * max_side;
const max_parseable_input_length: usize = 2 + 2 * max_cells + 1;

fn sampleCode(input: [*]const i64, base: usize, side: usize, row: usize,
    column: usize, q: usize, stride: usize) usize {
    var code: usize = 0;
    for (0..q) |step| {
        const at = base + row * side + column + step * stride;
        code = 4 * code + @as(usize, @intCast(input[at]));
    }
    return code;
}

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn two_dimensional_k_mismatch_linear_templates(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_parseable_input_length) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 3 or n_value > 12 or m_value < 3 or m_value > n_value) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    const text_size = n * n;
    const pattern_size = m * m;
    if (length != 2 + text_size + pattern_size) return -1;
    const pattern_base = 2 + text_size;
    for (0..text_size + pattern_size) |index| {
        if (input[2 + index] < 0 or input[2 + index] > 3) return -1;
    }

    var q: usize = 1;
    var code_capacity: usize = 4;
    while (code_capacity < pattern_size) : (q += 1) code_capacity *= 4;
    const stride = m / q;
    const final_offset = (q - 1) * stride;
    var heads = [_]i16{-1} ** 256;
    var next_address = [_]i16{0} ** max_cells;
    var sample_row = [_]u8{0} ** max_cells;
    var sample_column = [_]u8{0} ** max_cells;
    var sample_count: usize = 0;
    for (0..m) |row| {
        for (0..stride) |residue| {
            const code = sampleCode(input, pattern_base, m, row, residue, q, stride);
            sample_row[sample_count] = @intCast(row);
            sample_column[sample_count] = @intCast(residue);
            next_address[sample_count] = heads[code];
            heads[code] = @intCast(sample_count);
            sample_count += 1;
        }
    }

    var considered = [_]bool{false} ** max_cells;
    var matched = [_]bool{false} ** max_cells;
    const starts = n - m + 1;
    for (0..n) |text_row| {
        if (text_row % m < m - 2) continue;
        var text_column: usize = 0;
        while (text_column + final_offset < n) : (text_column += stride) {
            const code = sampleCode(input, 2, n, text_row, text_column, q, stride);
            var address = heads[code];
            while (address >= 0) {
                const slot: usize = @intCast(address);
                const candidate_row: isize = @as(isize, @intCast(text_row)) - @as(isize, @intCast(sample_row[slot]));
                const candidate_column: isize = @as(isize, @intCast(text_column)) - @as(isize, @intCast(sample_column[slot]));
                if (candidate_row >= 0 and candidate_column >= 0 and
                    candidate_row < @as(isize, @intCast(starts)) and
                    candidate_column < @as(isize, @intCast(starts))) {
                    const row: usize = @intCast(candidate_row);
                    const column: usize = @intCast(candidate_column);
                    const candidate = row * n + column;
                    if (!considered[candidate]) {
                        considered[candidate] = true;
                        var mismatches: usize = 0;
                        var dr: usize = 0;
                        while (dr < m and mismatches < 2) : (dr += 1) {
                            var dc: usize = 0;
                            while (dc < m) : (dc += 1) {
                                const text_at = 2 + (row + dr) * n + column + dc;
                                const pattern_at = pattern_base + dr * m + dc;
                                if (input[text_at] != input[pattern_at]) {
                                    mismatches += 1;
                                    if (mismatches == 2) break;
                                }
                            }
                        }
                        matched[candidate] = mismatches <= 1;
                    }
                }
                address = next_address[slot];
            }
        }
    }

    var match_count: usize = 0;
    for (0..starts) |row| {
        for (0..starts) |column| {
            if (matched[row * n + column]) match_count += 1;
        }
    }
    const output_bytes = 8 * (1 + 2 * match_count);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    putI64Le(output, 0, @intCast(match_count));
    var word: usize = 1;
    for (0..starts) |row| {
        for (0..starts) |column| {
            if (!matched[row * n + column]) continue;
            putI64Le(output, 8 * word, @intCast(row)); word += 1;
            putI64Le(output, 8 * word, @intCast(column)); word += 1;
        }
    }
    return @intCast(output_bytes);
}
