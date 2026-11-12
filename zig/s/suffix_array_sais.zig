const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;
const MAX_ALPHABET: usize = 256;

fn induce(
    symbols: [*]const i32,
    length: usize,
    upper: usize,
    is_s: [*]const bool,
    sum_s: [*]const i32,
    sum_l: [*]const i32,
    ordered_lms: [*]const i32,
    lms_count: usize,
    suffixes: [*]i32,
) void {
    var bucket: [MAX_ALPHABET + 2]i32 = @splat(0);
    for (0..length) |i| suffixes[i] = -1;
    for (0..(upper + 2)) |i| bucket[i] = sum_s[i];
    for (0..lms_count) |i| {
        const position = ordered_lms[i];
        const symbol: usize = @intCast(symbols[@intCast(position)]);
        suffixes[@intCast(bucket[symbol])] = position;
        bucket[symbol] += 1;
    }
    for (0..(upper + 2)) |i| bucket[i] = sum_l[i];
    for (0..length) |i| {
        const position = suffixes[i];
        if (position > 0 and !is_s[@intCast(position - 1)]) {
            const previous: usize = @intCast(position - 1);
            const symbol: usize = @intCast(symbols[previous]);
            suffixes[@intCast(bucket[symbol])] = position - 1;
            bucket[symbol] += 1;
        }
    }
    for (0..(upper + 2)) |i| bucket[i] = sum_l[i];
    var i = length;
    while (i > 0) {
        i -= 1;
        const position = suffixes[i];
        if (position > 0 and is_s[@intCast(position - 1)]) {
            const previous: usize = @intCast(position - 1);
            const symbol: usize = @intCast(symbols[previous] + 1);
            bucket[symbol] -= 1;
            suffixes[@intCast(bucket[symbol])] = position - 1;
        }
    }
}

fn sameLmsSubstring(
    symbols: [*]const i32,
    length: usize,
    is_s: [*]const bool,
    lms_map: [*]const i32,
    left: usize,
    right: usize,
) bool {
    if (left == right) return true;
    for (0..length) |offset| {
        const a = left + offset;
        const b = right + offset;
        if (a >= length or b >= length or symbols[a] != symbols[b] or is_s[a] != is_s[b]) return false;
        const a_lms = offset > 0 and lms_map[a] >= 0;
        const b_lms = offset > 0 and lms_map[b] >= 0;
        if (a_lms or b_lms) return a_lms and b_lms;
    }
    return false;
}

fn sais(symbols: [*]const i32, length: usize, upper: usize, suffixes: [*]i32) void {
    if (length == 0) return;
    if (length <= 2) {
        for (0..length) |i| suffixes[i] = @intCast(i);
        if (length == 2 and symbols[0] >= symbols[1]) {
            suffixes[0] = 1;
            suffixes[1] = 0;
        }
        return;
    }

    var is_s: [MAX_TEXT_LENGTH + 1]bool = @splat(false);
    is_s[length - 1] = true;
    var i = length - 1;
    while (i > 0) {
        i -= 1;
        is_s[i] = symbols[i] < symbols[i + 1] or (symbols[i] == symbols[i + 1] and is_s[i + 1]);
    }
    var lms_map: [MAX_TEXT_LENGTH + 2]i32 = @splat(-1);
    var lms: [MAX_TEXT_LENGTH + 1]i32 = @splat(0);
    var lms_count: usize = 0;
    for (1..length) |position| {
        if (!is_s[position - 1] and is_s[position]) {
            lms_map[position] = @intCast(lms_count);
            lms[lms_count] = @intCast(position);
            lms_count += 1;
        }
    }
    var sum_s: [MAX_ALPHABET + 2]i32 = @splat(0);
    var sum_l: [MAX_ALPHABET + 2]i32 = @splat(0);
    for (0..length) |position| {
        const symbol: usize = @intCast(symbols[position]);
        if (is_s[position]) {
            sum_l[symbol + 1] += 1;
        } else {
            sum_s[symbol] += 1;
        }
    }
    for (0..(upper + 1)) |symbol| {
        sum_s[symbol] += sum_l[symbol];
        sum_l[symbol + 1] += sum_s[symbol];
    }

    var suffixes_work: [MAX_TEXT_LENGTH + 1]i32 = @splat(-1);
    induce(symbols, length, upper, &is_s[0], &sum_s[0], &sum_l[0], &lms[0], lms_count, &suffixes_work[0]);
    var sorted_lms: [MAX_TEXT_LENGTH + 1]i32 = @splat(0);
    var sorted_count: usize = 0;
    for (0..length) |position| {
        const lms_position = suffixes_work[position];
        if (lms_position >= 0 and lms_map[@intCast(lms_position)] >= 0) {
            sorted_lms[sorted_count] = lms_position;
            sorted_count += 1;
        }
    }
    var reduced: [MAX_TEXT_LENGTH + 1]i32 = @splat(0);
    var reduced_upper: usize = 0;
    for (0..sorted_count) |index| {
        if (index > 0 and !sameLmsSubstring(
            symbols,
            length,
            &is_s[0],
            &lms_map[0],
            @intCast(sorted_lms[index - 1]),
            @intCast(sorted_lms[index]),
        )) reduced_upper += 1;
        reduced[@intCast(lms_map[@intCast(sorted_lms[index])])] = @intCast(reduced_upper);
    }
    var reduced_order: [MAX_TEXT_LENGTH + 1]i32 = @splat(0);
    if (reduced_upper + 1 == sorted_count) {
        for (0..sorted_count) |index| {
            reduced_order[@intCast(reduced[index])] = @intCast(index);
        }
    } else {
        sais(&reduced[0], sorted_count, reduced_upper, &reduced_order[0]);
    }
    var ordered_lms: [MAX_TEXT_LENGTH + 1]i32 = @splat(0);
    for (0..sorted_count) |index| {
        ordered_lms[index] = lms[@intCast(reduced_order[index])];
    }
    induce(symbols, length, upper, &is_s[0], &sum_s[0], &sum_l[0], &ordered_lms[0], sorted_count, suffixes);
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn suffix_array_sais(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > MAX_TEXT_LENGTH) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 1) return -1;
    for (0..count) |i| if (values[i + 1] < 0 or values[i + 1] > 255) return -1;
    const output_bytes = count * 8;
    if (output == null or capacity < output_bytes) return -2;
    var symbols: [MAX_TEXT_LENGTH + 1]i32 = @splat(0);
    for (0..count) |i| symbols[i] = @intCast(values[i + 1] + 1);
    symbols[count] = 0;
    var suffixes: [MAX_TEXT_LENGTH + 1]i32 = @splat(0);
    sais(&symbols[0], count + 1, MAX_ALPHABET, &suffixes[0]);
    var out: usize = 0;
    for (0..(count + 1)) |i| {
        if (suffixes[i] == @as(i32, @intCast(count))) continue;
        putI64Le(output, out * 8, suffixes[i]);
        out += 1;
    }
    return @intCast(output_bytes);
}
