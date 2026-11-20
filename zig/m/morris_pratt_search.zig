const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT: usize = 4227;

export fn morris_pratt_search(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_TEXT)) or
        input[1] < 1 or input[1] > @as(i64, @intCast(MAX_PATTERN))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + m) return -1;
    const pattern_start = 2 + n;
    for (0..n + m) |q| if (input[2 + q] < 0 or input[2 + q] > 3) return -1;

    var mp_next: [MAX_PATTERN + 1]isize = undefined;
    mp_next[0] = -1;
    for (0..m) |index| {
        var border = mp_next[index];
        while (border >= 0 and input[pattern_start + index] != input[pattern_start + @as(usize, @intCast(border))]) {
            border = mp_next[@as(usize, @intCast(border))];
        }
        mp_next[index + 1] = border + 1;
    }

    var matched: isize = 0;
    var count: i64 = 0;
    var offset_sum: i64 = 0;
    var offset_xor: i64 = 0;
    for (0..n) |text_index| {
        while (matched >= 0 and
            input[pattern_start + @as(usize, @intCast(matched))] != input[2 + text_index]) {
            matched = mp_next[@as(usize, @intCast(matched))];
        }
        matched += 1;
        if (@as(usize, @intCast(matched)) == m) {
            const start: i64 = @intCast(text_index + 1 - m);
            count += 1;
            offset_sum += start;
            offset_xor ^= start;
            matched = mp_next[m];
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
