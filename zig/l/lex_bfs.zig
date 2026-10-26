const max_n: usize = 16;
const max_m: usize = 120;
const max_input: usize = 243;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn lex_bfs(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const start64 = input[2];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 120 or start64 < 0 or
        start64 >= n64 or length != 3 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const start: usize = @intCast(start64);
    var adjacency: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    for (0..m) |edge| {
        const u64 = input[3 + 2 * edge];
        const v64 = input[4 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var labels: [max_n][max_n]i64 = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    var label_len: [max_n]usize = [_]usize{0} ** max_n;
    var order: [max_n]i64 = [_]i64{0} ** max_n;
    var selected: [max_n]bool = [_]bool{false} ** max_n;
    var current = start;
    for (0..n) |step| {
        if (step > 0) {
            var have_best = false;
            for (0..n) |vertex| {
                if (selected[vertex]) continue;
                if (!have_best) { current = vertex; have_best = true; continue; }
                const shared = @min(label_len[vertex], label_len[current]);
                var position: usize = 0;
                var decided = false;
                while (position < shared) : (position += 1) {
                    if (labels[vertex][position] != labels[current][position]) {
                        if (labels[vertex][position] > labels[current][position]) current = vertex;
                        decided = true;
                        break;
                    }
                }
                if (!decided and (label_len[vertex] > label_len[current] or
                    (label_len[vertex] == label_len[current] and vertex < current))) current = vertex;
            }
        }
        selected[current] = true;
        order[step] = @intCast(current);
        for (0..n) |neighbor| {
            if (!adjacency[current][neighbor] or selected[neighbor]) continue;
            var position = label_len[neighbor];
            while (position > 0) : (position -= 1)
                labels[neighbor][position] = labels[neighbor][position - 1];
            labels[neighbor][0] = @intCast(step);
            label_len[neighbor] += 1;
        }
    }
    for (0..n) |index| storeI64LE(output, 8 * index, order[index]);
    return @intCast(output_bytes);
}
