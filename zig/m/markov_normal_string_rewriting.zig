const MAX_RULES: usize = 8;
const MAX_WORD: usize = 64;
const MAX_INPUT: usize = 204;

export fn markov_normal_string_rewriting(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > MAX_RULES or values[1] < 0 or values[1] > 32 or
        values[2] < 0 or values[2] > 48) return -1;
    const count: usize = @intCast(values[0]);
    const budget: usize = @intCast(values[1]);
    var word_len: usize = @intCast(values[2]);
    if (length < 3 + word_len) return -1;
    var word: [MAX_WORD]i64 = @splat(0);
    var cursor: usize = 3;
    for (0..word_len) |i| {
        if (values[cursor] < 0 or values[cursor] > 25) return -1;
        word[i] = values[cursor];
        cursor += 1;
    }
    var kinds: [MAX_RULES]i64 = @splat(0);
    var lhs_len: [MAX_RULES]usize = @splat(0);
    var rhs_len: [MAX_RULES]usize = @splat(0);
    var lhs: [MAX_RULES * 8]i64 = @splat(0);
    var rhs: [MAX_RULES * 8]i64 = @splat(0);
    for (0..count) |r| {
        if (cursor + 3 > length) return -1;
        const kind = values[cursor];
        const left_value = values[cursor + 1];
        const right_value = values[cursor + 2];
        cursor += 3;
        if ((kind != 0 and kind != 1) or left_value < 1 or left_value > 8 or
            right_value < 0 or right_value > 8) return -1;
        kinds[r] = kind;
        lhs_len[r] = @intCast(left_value);
        rhs_len[r] = @intCast(right_value);
        if (cursor + lhs_len[r] + rhs_len[r] > length) return -1;
        for (0..lhs_len[r]) |j| {
            if (values[cursor] < 0 or values[cursor] > 25) return -1;
            lhs[r * 8 + j] = values[cursor];
            cursor += 1;
        }
        for (0..rhs_len[r]) |j| {
            if (values[cursor] < 0 or values[cursor] > 25) return -1;
            rhs[r * 8 + j] = values[cursor];
            cursor += 1;
        }
    }
    if (cursor != length) return -1;

    var rewrites: usize = 0;
    var halt: u8 = 0;
    while (true) {
        var selected = count;
        var offset: usize = 0;
        for (0..count) |r| {
            if (selected != count) break;
            if (lhs_len[r] > word_len) continue;
            for (0..word_len - lhs_len[r] + 1) |at| {
                var equal = true;
                for (0..lhs_len[r]) |j| {
                    if (word[at + j] != lhs[r * 8 + j]) { equal = false; break; }
                }
                if (equal) { selected = r; offset = at; break; }
            }
        }
        if (selected == count) { halt = 0; break; }
        if (rewrites == budget) { halt = 2; break; }
        const new_len = word_len - lhs_len[selected] + rhs_len[selected];
        if (new_len > MAX_WORD) return -3;
        var next: [MAX_WORD]i64 = @splat(0);
        var out: usize = 0;
        for (0..offset) |i| { next[out] = word[i]; out += 1; }
        for (0..rhs_len[selected]) |i| { next[out] = rhs[selected * 8 + i]; out += 1; }
        for (offset + lhs_len[selected]..word_len) |i| { next[out] = word[i]; out += 1; }
        word = next;
        word_len = new_len;
        rewrites += 1;
        if (kinds[selected] == 1) { halt = 1; break; }
    }
    const required = 3 + word_len;
    if (output == null or capacity < required) return -2;
    const result = output.?[0..required];
    result[0] = halt;
    result[1] = @intCast(rewrites);
    result[2] = @intCast(word_len);
    for (0..word_len) |i| result[i + 3] = @intCast(word[i]);
    return @intCast(required);
}
