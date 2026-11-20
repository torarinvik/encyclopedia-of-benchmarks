const MAX_TEXT: usize = 16;
const MAX_PARENS: usize = 8;
const MAX_ROWS: usize = 256;
const MAX_OUTPUT: usize = 4354;

fn bitCount(value0: usize) usize {
    var value = value0;
    var count: usize = 0;
    while (value != 0) : (value >>= 1) count += value & 1;
    return count;
}
fn balanced(text: *const [MAX_TEXT]u8, n: usize) bool {
    var depth: i32 = 0;
    for (0..n) |i| {
        if (text[i] == '(') depth += 1 else if (text[i] == ')') {
            depth -= 1;
            if (depth < 0) return false;
        }
    }
    return depth == 0;
}
fn lessKey(key: *const [MAX_TEXT]u8, key_len: usize,
    rows: *const [MAX_ROWS * MAX_TEXT]u8, b: usize, bl: usize) bool {
    const common = @min(key_len, bl);
    for (0..common) |i| {
        const av = key[i];
        const bv = rows[b * MAX_TEXT + i];
        if (av != bv) return av < bv;
    }
    return key_len < bl;
}

export fn minimum_parenthesis_removal_bfs(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_TEXT + 1) return -1;
    const values = input.?;
    const n64 = values[0];
    if (n64 < 0 or n64 > MAX_TEXT or length != @as(usize, @intCast(n64)) + 1) return -1;
    const n: usize = @intCast(n64);
    var text: [MAX_TEXT]u8 = [_]u8{0} ** MAX_TEXT;
    var positions: [MAX_PARENS]usize = [_]usize{0} ** MAX_PARENS;
    var p: usize = 0;
    for (0..n) |i| {
        const value = values[i + 1];
        if (value == '(' or value == ')') {
            if (p == MAX_PARENS) return -1;
            positions[p] = i;
            p += 1;
        } else if (value < 'a' or value > 'z') return -1;
        text[i] = @intCast(value);
    }
    var rows: [MAX_ROWS * MAX_TEXT]u8 = [_]u8{0} ** (MAX_ROWS * MAX_TEXT);
    var sizes: [MAX_ROWS]u8 = [_]u8{0} ** MAX_ROWS;
    var count: usize = 0;
    const states = @as(usize, 1) << @intCast(p);
    for (0..p + 1) |deletions| {
        for (0..states) |mask| {
            if (bitCount(mask) != deletions) continue;
            var candidate: [MAX_TEXT]u8 = [_]u8{0} ** MAX_TEXT;
            var used: usize = 0;
            var ordinal: usize = 0;
            for (0..n) |i| {
                const at_paren = ordinal < p and positions[ordinal] == i;
                const remove = at_paren and (mask & (@as(usize, 1) << @intCast(ordinal))) != 0;
                if (at_paren) ordinal += 1;
                if (!remove) { candidate[used] = text[i]; used += 1; }
            }
            if (!balanced(&candidate, used)) continue;
            var duplicate = false;
            for (0..count) |r| {
                if (sizes[r] != used) continue;
                var same = true;
                for (0..used) |j| {
                    if (rows[r * MAX_TEXT + j] != candidate[j]) same = false;
                }
                if (same) duplicate = true;
            }
            if (!duplicate) {
                for (0..used) |j| rows[count * MAX_TEXT + j] = candidate[j];
                sizes[count] = @intCast(used);
                count += 1;
            }
        }
        if (count != 0) break;
    }
    if (count == 0) { sizes[0] = 0; count = 1; }
    for (1..count) |i| {
        var key: [MAX_TEXT]u8 = [_]u8{0} ** MAX_TEXT;
        const key_len: usize = sizes[i];
        for (0..key_len) |j| key[j] = rows[i * MAX_TEXT + j];
        var j = i;
        while (j > 0 and lessKey(&key, key_len, &rows, j - 1, sizes[j - 1])) : (j -= 1) {
            for (0..sizes[j - 1]) |k| rows[j * MAX_TEXT + k] = rows[(j - 1) * MAX_TEXT + k];
            sizes[j] = sizes[j - 1];
        }
        for (0..key_len) |k| rows[j * MAX_TEXT + k] = key[k];
        sizes[j] = @intCast(key_len);
    }
    var needed: usize = 2;
    for (0..count) |r| needed += 1 + sizes[r];
    if (needed > MAX_OUTPUT) return -1;
    if (output == null or capacity < needed) return -2;
    const out = output.?;
    out[0] = @intCast(count & 255);
    out[1] = @intCast(count >> 8);
    var pos: usize = 2;
    for (0..count) |r| {
        out[pos] = sizes[r];
        pos += 1;
        for (0..sizes[r]) |j| { out[pos] = rows[r * MAX_TEXT + j]; pos += 1; }
    }
    return @intCast(pos);
}
