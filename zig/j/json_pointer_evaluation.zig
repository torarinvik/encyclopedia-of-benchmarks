const MAX_NODES: usize = 32;
const MAX_POINTER: usize = 64;
const RECORD_WORDS: usize = 21;

fn field(values: [*]const i64, base: usize, node: usize, offset: usize) i64 {
    return values[base + node * RECORD_WORDS + offset];
}

pub export fn json_pointer_evaluation(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 3) return -1;
    const n_value = values[0];
    const root_value = values[1];
    const pointer_value = values[2];
    if (n_value < 1 or n_value > MAX_NODES or root_value < 0 or root_value >= n_value
        or pointer_value < 0 or pointer_value > MAX_POINTER) return -1;
    const n: usize = @intCast(n_value);
    const root: usize = @intCast(root_value);
    const pointer_length: usize = @intCast(pointer_value);
    const base = 3 + pointer_length;
    if (length != base + n * RECORD_WORDS) return -1;
    for (0..pointer_length) |i| if (values[3 + i] < 0 or values[3 + i] > 127) return -1;
    if (pointer_length != 0 and values[3] != '/') return -1;
    var syntax_pos: usize = 1;
    while (syntax_pos < pointer_length) : (syntax_pos += 1) {
        if (values[3 + syntax_pos] == '~') {
            syntax_pos += 1;
            if (syntax_pos >= pointer_length) return -1;
            const escaped = values[3 + syntax_pos];
            if (escaped != '0' and escaped != '1') return -1;
        }
    }

    for (0..n) |i| {
        const kind = field(values, base, i, 0);
        const parent = field(values, base, i, 1);
        const key_length = field(values, base, i, 2);
        const array_index = field(values, base, i, 19);
        if (kind < 0 or kind > 2 or key_length < 0 or key_length > 16) return -1;
        if (i == root) {
            if (parent != -1 or key_length != 0 or array_index != -1) return -1;
        } else {
            if (parent < 0 or parent >= n_value or @as(usize, @intCast(parent)) == i) return -1;
            const parent_kind = field(values, base, @intCast(parent), 0);
            if (parent_kind < 0 or parent_kind > 1) return -1;
            if (parent_kind == 0) { if (array_index != -1) return -1; }
            else if (key_length != 0 or array_index < 0) return -1;
        }
        for (0..16) |k| {
            const ch = field(values, base, i, 3 + k);
            if (k < @as(usize, @intCast(key_length))) {
                if (ch < 0 or ch > 127) return -1;
            } else if (ch != 0) return -1;
        }
        var cursor = i;
        var hops: usize = 0;
        while (cursor != root and hops < n) : (hops += 1) {
            const next = field(values, base, cursor, 1);
            if (next < 0 or next >= n_value) return -1;
            cursor = @intCast(next);
        }
        if (cursor != root) return -1;
    }
    for (0..n) |parent| {
        if (field(values, base, parent, 0) != 1) continue;
        var children: usize = 0;
        for (0..n) |child| if (field(values, base, child, 1) == @as(i64, @intCast(parent))) { children += 1; };
        for (0..n) |child| {
            if (field(values, base, child, 1) != @as(i64, @intCast(parent))) continue;
            const index = field(values, base, child, 19);
            if (index < 0 or @as(u64, @intCast(index)) >= children) return -1;
            for (0..child) |prior| if (field(values, base, prior, 1) == @as(i64, @intCast(parent))
                and field(values, base, prior, 19) == index) return -1;
        }
    }

    var current = root;
    if (pointer_length == 0) return @intCast(current);
    var token: [MAX_POINTER]i64 = @splat(0);
    var token_length: usize = 0;
    var pos: usize = 1;
    while (pos <= pointer_length) {
        if (pos == pointer_length or values[3 + pos] == '/') {
            const kind = field(values, base, current, 0);
            var found = n;
            var matches: usize = 0;
            if (kind == 0) {
                for (0..n) |child| {
                    if (field(values, base, child, 1) != @as(i64, @intCast(current))
                        or field(values, base, child, 2) != @as(i64, @intCast(token_length))) continue;
                    var k: usize = 0;
                    while (k < token_length and field(values, base, child, 3 + k) == token[k]) : (k += 1) {}
                    if (k == token_length) { found = child; matches += 1; }
                }
            } else if (kind == 1) {
                if (token_length == 0 or (token_length > 1 and token[0] == '0')) return -2;
                var index: i64 = 0;
                for (token[0..token_length]) |ch| {
                    if (ch < '0' or ch > '9') return -2;
                    index = index * 10 + ch - '0';
                    if (index > MAX_NODES) return -2;
                }
                for (0..n) |child| if (field(values, base, child, 1) == @as(i64, @intCast(current))
                    and field(values, base, child, 19) == index) { found = child; matches += 1; };
            } else return -2;
            if (matches != 1) return -2;
            current = found;
            token_length = 0;
            pos += 1;
            continue;
        }
        var ch = values[3 + pos];
        if (ch == '~') {
            pos += 1;
            if (pos >= pointer_length) return -1;
            const escaped = values[3 + pos];
            if (escaped == '0') ch = '~' else if (escaped == '1') ch = '/' else return -1;
        }
        token[token_length] = ch;
        token_length += 1;
        pos += 1;
    }
    return @intCast(current);
}
