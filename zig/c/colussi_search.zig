const MAX_TEXT_LENGTH: usize = 4096;
const MAX_PATTERN_LENGTH: usize = 128;
const MAX_INPUT_LENGTH: usize = 4227;

fn preprocess(pattern: *const [MAX_PATTERN_LENGTH + 1]u8, pattern_length: usize,
    h: *[MAX_PATTERN_LENGTH + 1]usize,
    next_table: *[MAX_PATTERN_LENGTH + 1]usize,
    shift: *[MAX_PATTERN_LENGTH + 1]usize) isize {
    var hmax: [MAX_PATTERN_LENGTH + 2]usize = @splat(0);
    var kmin: [MAX_PATTERN_LENGTH + 1]usize = @splat(0);
    var rmin: [MAX_PATTERN_LENGTH + 1]usize = @splat(0);
    var nhd0: [MAX_PATTERN_LENGTH + 1]usize = @splat(0);
    var i: usize = 1;
    var k: usize = 1;
    while (true) {
        while (pattern[i] == pattern[i - k]) i += 1;
        hmax[k] = i;
        var q = k + 1;
        while (hmax[q - k] + k < i) : (q += 1) hmax[q] = hmax[q - k] + k;
        k = q;
        if (k == i + 1) i = k;
        if (k > pattern_length) break;
    }
    var position = pattern_length;
    while (position > 0) {
        if (hmax[position] < pattern_length) kmin[hmax[position]] = position;
        position -= 1;
    }
    var r = pattern_length;
    position = pattern_length;
    while (position > 0) {
        position -= 1;
        if (hmax[position + 1] == pattern_length) r = position + 1;
        rmin[position] = if (kmin[position] == 0) r else 0;
    }

    var nohole_last: isize = -1;
    var hole_at = pattern_length;
    for (0..pattern_length) |index| {
        if (kmin[index] == 0) {
            hole_at -= 1;
            h[hole_at] = index;
        } else {
            nohole_last += 1;
            h[@intCast(nohole_last)] = index;
        }
    }
    const nd = nohole_last;
    var index: usize = 0;
    while (@as(isize, @intCast(index)) <= nd) : (index += 1) shift[index] = kmin[h[index]];
    index = @intCast(nd + 1);
    while (index < pattern_length) : (index += 1) shift[index] = rmin[h[index]];
    shift[pattern_length] = rmin[0];

    var nohole_count: usize = 0;
    for (0..pattern_length) |position_index| {
        nhd0[position_index] = nohole_count;
        if (kmin[position_index] > 0) nohole_count += 1;
    }
    index = 0;
    while (@as(isize, @intCast(index)) <= nd) : (index += 1) next_table[index] = nhd0[h[index] - kmin[h[index]]];
    index = @intCast(nd + 1);
    while (index < pattern_length) : (index += 1) next_table[index] = nhd0[pattern_length - rmin[h[index]]];
    next_table[pattern_length] = nhd0[pattern_length - rmin[h[pattern_length - 1]]];
    return nd;
}

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const text_length64 = input[0];
    const pattern_length64 = input[1];
    if (text_length64 < 0 or text_length64 > MAX_TEXT_LENGTH
        or pattern_length64 < 1 or pattern_length64 > MAX_PATTERN_LENGTH) return null;
    const text_length: usize = @intCast(text_length64);
    const pattern_length: usize = @intCast(pattern_length64);
    if (input.len != 2 + text_length + pattern_length) return null;

    var text: [MAX_TEXT_LENGTH]u8 = @splat(0);
    var pattern: [MAX_PATTERN_LENGTH + 1]u8 = @splat(0);
    for (0..text_length) |index| {
        const symbol = input[2 + index];
        if (symbol < 0 or symbol > 3) return null;
        text[index] = @intCast(symbol);
    }
    const pattern_offset = 2 + text_length;
    for (0..pattern_length) |index| {
        const symbol = input[pattern_offset + index];
        if (symbol < 0 or symbol > 3) return null;
        pattern[index] = @intCast(symbol);
    }
    pattern[pattern_length] = 4;
    if (text_length < pattern_length) return 0;

    var h: [MAX_PATTERN_LENGTH + 1]usize = @splat(0);
    var next_table: [MAX_PATTERN_LENGTH + 1]usize = @splat(0);
    var shift: [MAX_PATTERN_LENGTH + 1]usize = @splat(0);
    const nd = preprocess(&pattern, pattern_length, &h, &next_table, &shift);
    var i: usize = 0;
    var j: usize = 0;
    var last: isize = -1;
    var match_count: i64 = 0;
    var offset_sum: i64 = 0;
    var offset_xor: i64 = 0;
    while (j <= text_length - pattern_length) {
        while (i < pattern_length and last < @as(isize, @intCast(j + h[i])) and pattern[h[i]] == text[j + h[i]]) i += 1;
        if (i >= pattern_length or last >= @as(isize, @intCast(j + h[i]))) {
            match_count += 1;
            offset_sum += @intCast(j);
            offset_xor ^= @intCast(j);
            i = pattern_length;
        }
        if (@as(isize, @intCast(i)) > nd) last = @intCast(j + pattern_length - 1);
        j += shift[i];
        i = next_table[i];
    }
    return (match_count << 36) | (offset_sum << 12) | offset_xor;
}

export fn colussi_search(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
