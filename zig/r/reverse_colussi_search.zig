const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT_LENGTH: usize = 4227;

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 0 or n64 > MAX_TEXT or m64 < 1 or m64 > MAX_PATTERN) return null;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (input.len != 2 + n + m) return null;
    var text: [MAX_TEXT]u8 = @splat(0);
    var pattern: [MAX_PATTERN]u8 = @splat(0);
    for (0..n) |q| {
        const value = input[2 + q];
        if (value < 0 or value > 3) return null;
        text[q] = @intCast(value);
    }
    for (0..m) |q| {
        const value = input[2 + n + q];
        if (value < 0 or value > 3) return null;
        pattern[q] = @intCast(value);
    }
    if (n < m) return 0;

    var hmin: [MAX_PATTERN + 1]i32 = @splat(0);
    var kmin: [MAX_PATTERN]i32 = @splat(0);
    var rmin: [MAX_PATTERN]i32 = @splat(0);
    var order: [MAX_PATTERN]i32 = @splat(0);
    var good_suffix: [MAX_PATTERN + 1]i32 = @splat(0);
    var bad_character: [4 * (MAX_PATTERN + 1)]i32 = @splat(0);
    var shift: usize = 1;
    while (shift <= m) : (shift += 1) {
        var last_mismatch = shift - 1;
        var pos = shift;
        while (pos < m) : (pos += 1) {
            if (pattern[pos] != pattern[pos - shift]) last_mismatch = pos;
        }
        hmin[shift] = @intCast(last_mismatch);
    }
    var down: isize = @intCast(m);
    while (down >= 1) : (down -= 1) {
        const index: usize = @intCast(down);
        const end: usize = @intCast(hmin[index]);
        if (end != m - 1) kmin[end] = @intCast(index);
    }
    var next_boundary = m;
    var end_signed: isize = @as(isize, @intCast(m)) - 1;
    while (end_signed >= 0) : (end_signed -= 1) {
        const end: usize = @intCast(end_signed);
        if (hmin[end + 1] == end_signed) next_boundary = end + 1;
        rmin[end] = @intCast(next_boundary);
    }

    order[0] = @intCast(m - 1);
    var cursor: usize = 0;
    shift = 1;
    while (shift <= m) : (shift += 1) {
        const h_end: usize = @intCast(hmin[shift]);
        if (h_end != m - 1 and kmin[h_end] == @as(i32, @intCast(shift))) {
            cursor += 1;
            order[cursor] = @intCast(h_end);
            good_suffix[cursor] = @intCast(shift);
        }
    }
    var end_desc: isize = @as(isize, @intCast(m)) - 2;
    cursor = m - 1;
    while (end_desc >= 0) : (end_desc -= 1) {
        const end: usize = @intCast(end_desc);
        if (kmin[end] == 0) {
            order[cursor] = @intCast(end);
            good_suffix[cursor] = rmin[end];
            cursor -= 1;
        }
    }
    good_suffix[m] = rmin[0];

    for (0..4) |symbol| {
        var prior_shift: usize = 1;
        while (prior_shift <= m) : (prior_shift += 1) {
            const boundary: isize = @as(isize, @intCast(m)) - @as(isize, @intCast(prior_shift)) - 1;
            var candidate: usize = 1;
            while (candidate <= m) : (candidate += 1) {
                if (candidate < m and @as(usize, pattern[m - candidate - 1]) != symbol) continue;
                if (@as(isize, @intCast(candidate)) <= boundary and
                    pattern[m - candidate - prior_shift - 1] != pattern[@intCast(boundary)]) continue;
                bad_character[symbol * (MAX_PATTERN + 1) + prior_shift] = @intCast(candidate);
                break;
            }
        }
    }

    var count: i64 = 0;
    var offset_sum: i64 = 0;
    var offset_xor: i64 = 0;
    var start: usize = 0;
    var shift_state = m;
    const last_start = n - m;
    while (start <= last_start) {
        while (start <= last_start and pattern[m - 1] != text[start + m - 1]) {
            shift_state = @intCast(bad_character[@as(usize, text[start + m - 1]) * (MAX_PATTERN + 1) + shift_state]);
            start += shift_state;
        }
        if (start > last_start) break;
        var index: usize = 1;
        while (index < m and pattern[@intCast(order[index])] == text[start + @as(usize, @intCast(order[index]))]) : (index += 1) {}
        if (index == m) {
            count += 1;
            offset_sum += @intCast(start);
            offset_xor ^= @intCast(start);
        }
        shift_state = @intCast(good_suffix[index]);
        start += shift_state;
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}

export fn reverse_colussi_search(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
