const MAX_PATTERN: usize = 6;
const MAX_VARIABLES: usize = 12;
const MAX_FACTORS: usize = 8;
const MAX_TEXT: usize = 64;
const MAX_INPUT: usize = 53;
const MAX_OUTPUT_BYTES: usize = 520;

fn store_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn kmp_slp_jump_output(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 8 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    var cursor: usize = 0;
    const pattern_raw = input[cursor]; cursor += 1;
    if (pattern_raw < 1 or pattern_raw > @as(i64, MAX_PATTERN)) return -1;
    const pattern_length: usize = @intCast(pattern_raw);
    var pattern: [MAX_PATTERN]i64 = @splat(0);
    for (0..pattern_length) |i| {
        pattern[i] = input[cursor]; cursor += 1;
        if (pattern[i] < 0 or pattern[i] > 3) return -1;
    }
    if (cursor >= length) return -1;
    const variable_raw = input[cursor]; cursor += 1;
    if (variable_raw < 1 or variable_raw > @as(i64, MAX_VARIABLES)
        or cursor + 3 * @as(usize, @intCast(variable_raw)) + 1 > length) return -1;
    const variable_count: usize = @intCast(variable_raw);
    var kind: [MAX_VARIABLES]u8 = @splat(0);
    var first: [MAX_VARIABLES]usize = @splat(0);
    var second: [MAX_VARIABLES]usize = @splat(0);
    var terminal: [MAX_VARIABLES]i64 = @splat(0);
    var variable_length: [MAX_VARIABLES]usize = @splat(0);
    for (0..variable_count) |variable| {
        const kind_raw = input[cursor];
        const first_raw = input[cursor + 1];
        const second_raw = input[cursor + 2];
        cursor += 3;
        if (kind_raw == 0) {
            if (first_raw < 0 or first_raw > 3 or second_raw != 0) return -1;
            terminal[variable] = first_raw;
            variable_length[variable] = 1;
        } else if (kind_raw == 1) {
            if (first_raw < 0 or second_raw < 0 or first_raw >= @as(i64, @intCast(variable))
                or second_raw >= @as(i64, @intCast(variable))) return -1;
            kind[variable] = 1;
            first[variable] = @intCast(first_raw);
            second[variable] = @intCast(second_raw);
            variable_length[variable] = variable_length[first[variable]] + variable_length[second[variable]];
            if (variable_length[variable] > MAX_TEXT) return -1;
        } else return -1;
    }
    if (cursor >= length) return -1;
    const factor_raw = input[cursor]; cursor += 1;
    if (factor_raw < 1 or factor_raw > @as(i64, MAX_FACTORS)
        or cursor + @as(usize, @intCast(factor_raw)) != length) return -1;
    const factor_count: usize = @intCast(factor_raw);
    var factors: [MAX_FACTORS]usize = @splat(0);
    var text_length: usize = 0;
    for (0..factor_count) |i| {
        const factor = input[cursor]; cursor += 1;
        if (factor < 0 or factor >= variable_raw) return -1;
        factors[i] = @intCast(factor);
        text_length += variable_length[factors[i]];
        if (text_length > MAX_TEXT) return -1;
    }

    var failure: [MAX_PATTERN]usize = @splat(0);
    var border: usize = 0;
    for (1..pattern_length) |i| {
        while (border > 0 and pattern[i] != pattern[border]) border = failure[border - 1];
        if (pattern[i] == pattern[border]) border += 1;
        failure[i] = border;
    }
    var jump: [MAX_VARIABLES][MAX_PATTERN]usize = @splat(@splat(0));
    var output_mask: [MAX_VARIABLES][MAX_PATTERN]u64 = @splat(@splat(0));
    for (0..variable_count) |variable| {
        for (0..pattern_length) |state| {
            if (kind[variable] == 0) {
                var next = state;
                while (next > 0 and pattern[next] != terminal[variable]) next = failure[next - 1];
                if (pattern[next] == terminal[variable]) next += 1;
                if (next == pattern_length) {
                    output_mask[variable][state] = 1;
                    next = failure[pattern_length - 1];
                }
                jump[variable][state] = next;
            } else {
                const left = first[variable];
                const right = second[variable];
                const middle = jump[left][state];
                jump[variable][state] = jump[right][middle];
                output_mask[variable][state] = output_mask[left][state]
                    | (output_mask[right][middle] << @intCast(variable_length[left]));
            }
        }
    }
    var state: usize = 0;
    var offset: usize = 0;
    var end_offsets: u64 = 0;
    for (0..factor_count) |i| {
        const variable = factors[i];
        end_offsets |= output_mask[variable][state] << @intCast(offset);
        state = jump[variable][state];
        offset += variable_length[variable];
    }
    var words: [1 + MAX_TEXT]i64 = @splat(0);
    var occurrences: usize = 0;
    for (0..text_length) |ending| {
        if (((end_offsets >> @intCast(ending)) & 1) != 0) {
            if (ending + 1 < pattern_length) return -1;
            words[1 + occurrences] = @intCast(ending + 1 - pattern_length);
            occurrences += 1;
        }
    }
    words[0] = @intCast(occurrences);
    const output_bytes = 8 * (1 + occurrences);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..1 + occurrences) |word| store_i64_le(&staged, 8 * word, words[word]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
