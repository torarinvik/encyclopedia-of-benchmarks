// Clean-room GBBS Yoshida recursive MIS query; see package LICENSE.txt.
const max_n: usize = 12;
const max_m: usize = 24;
const max_input: usize = 52;
const max_cutoff: usize = 128;

fn hash64(value: u64) u64 {
    var mixed = value *% 3935559000370003845 +% 2691343689449507681;
    mixed ^= mixed >> 21;
    mixed ^= mixed << 37;
    mixed ^= mixed >> 4;
    mixed *%= 4768777513237032717;
    mixed ^= mixed << 20;
    mixed ^= mixed >> 41;
    mixed ^= mixed << 5;
    return mixed;
}

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn query(vertex: usize, degree: *const [max_n]usize,
    neighbors: *const [max_n][max_n]usize, priority: *const [max_n]u64,
    work: *usize, cutoff: usize) i64 {
    for (0..degree[vertex]) |index| {
        if (work.* == cutoff) return -1;
        const neighbor = neighbors[vertex][index];
        work.* += 1;
        if (priority[vertex] < priority[neighbor] or
            (priority[vertex] == priority[neighbor] and vertex <= neighbor)) break;
        const status = query(neighbor, degree, neighbors, priority, work, cutoff);
        if (status == 1) return 0;
        if (status == -1) return -1;
    }
    return 1;
}

export fn gbbs_yoshida_query_mis(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const root64 = input[2];
    const cutoff64 = input[3];
    if (n64 < 1 or n64 > 12 or m64 < 0 or m64 > 24 or root64 < 0 or root64 >= n64 or
        cutoff64 < 0 or cutoff64 > 128 or length != 4 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacent = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    var degree = [_]usize{0} ** max_n;
    for (0..m) |edge| {
        const u64 = input[4 + 2 * edge];
        const v64 = input[5 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
        degree[u] += 1;
        degree[v] += 1;
    }
    if (output_opt == null or capacity < 16) return -2;
    const output = output_opt.?;
    var priority = [_]u64{0} ** max_n;
    var neighbors = [_][max_n]usize{[_]usize{0} ** max_n} ** max_n;
    for (0..n) |vertex| priority[vertex] = hash64(@intCast(vertex));
    for (0..n) |vertex| {
        var inserted: usize = 0;
        for (0..n) |other| {
            if (adjacent[vertex][other]) {
                var position = inserted;
                while (position > 0) {
                    const previous = neighbors[vertex][position - 1];
                    if (priority[previous] < priority[other] or
                        (priority[previous] == priority[other] and previous < other)) break;
                    neighbors[vertex][position] = previous;
                    position -= 1;
                }
                neighbors[vertex][position] = other;
                inserted += 1;
            }
        }
    }
    var work: usize = 0;
    const status = query(@intCast(root64), &degree, &neighbors, &priority,
                         &work, @intCast(cutoff64));
    storeI64LE(output, 0, status);
    storeI64LE(output, 8, @intCast(work));
    return 16;
}
