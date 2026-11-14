// Uncompiled and unexecuted next-occurrence automaton draft.
export fn subsequence_automaton(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 354) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 64 or input[1] < 0 or input[1] > 32) return -1;
    const n: usize = @intCast(input[0]);
    const queries: usize = @intCast(input[1]);
    if (length < 2+n) return -1;
    for (0..n) |i| if (input[2+i] < 0 or input[2+i] > 3) { return -1; };
    var next: [65][4]usize = undefined;
    next[n] = @splat(n);
    var row = n;
    while (row > 0) {
        row -= 1;
        next[row] = next[row+1];
        next[row][@intCast(input[2+row])] = row;
    }
    var pos: usize = 2+n;
    var total: usize = 0;
    var answer: i64 = 0;
    for (0..queries) |q| {
        if (pos == length or input[pos] < 0 or input[pos] > 256) return -1;
        const count: usize = @intCast(input[pos]); pos += 1;
        if (count > 256-total or count > length-pos) return -1;
        var cursor: usize = 0;
        var matches = true;
        for (0..count) |i| {
            const symbol = input[pos+i];
            if (symbol < 0 or symbol > 3) return -1;
            if (matches) {
                const found = next[cursor][@intCast(symbol)];
                if (found == n) { matches = false; } else { cursor = found+1; }
            }
        }
        if (matches) answer += @intCast(q+1);
        pos += count; total += count;
    }
    return if (pos == length) answer else -1;
}
