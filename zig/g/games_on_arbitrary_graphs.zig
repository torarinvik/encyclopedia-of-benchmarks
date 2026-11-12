const MAX_V: usize = 16;
const MAX_E: usize = 32;
const MAX_INPUT: usize = 66;
const MAX_OUTPUT: usize = 17;

export fn games_on_arbitrary_graphs(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const packed = input[0..length];
    const nv = packed[0];
    const me = packed[1];
    if (nv < 0 or nv > @as(i64, @intCast(MAX_V)) or me < 0 or me > @as(i64, @intCast(MAX_E))) return -1;
    const n: usize = @intCast(nv);
    const m: usize = @intCast(me);
    if (length != 2 + 2 * m) return -1;

    var outmask: [MAX_V]u16 = @splat(0);
    var head: [MAX_V]i32 = @splat(-1);
    var edge_source: [MAX_E]usize = @splat(0);
    var edge_next: [MAX_E]i32 = @splat(-1);
    var remaining: [MAX_V]usize = @splat(0);
    var status: [MAX_V]u8 = @splat(0);
    var queue: [MAX_V]usize = @splat(0);
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    var unique_edges: usize = 0;
    for (0..m) |index| {
        const sv = packed[2 + 2 * index];
        const tv = packed[3 + 2 * index];
        if (sv < 0 or sv >= nv or tv < 0 or tv >= nv) return -1;
        const s: usize = @intCast(sv);
        const t: usize = @intCast(tv);
        const bit: u16 = @as(u16, 1) << @intCast(t);
        if ((outmask[s] & bit) == 0) {
            outmask[s] |= bit;
            edge_source[unique_edges] = s;
            edge_next[unique_edges] = head[t];
            head[t] = @intCast(unique_edges);
            unique_edges += 1;
            remaining[s] += 1;
        }
    }

    var first: usize = 0;
    var count: usize = 0;
    for (0..n) |vertex| {
        if (remaining[vertex] == 0) {
            status[vertex] = 2;
            queue[count] = vertex;
            count += 1;
        }
    }
    while (first < count) {
        const resolved = queue[first];
        first += 1;
        var edge = head[resolved];
        while (edge >= 0) {
            const edge_index: usize = @intCast(edge);
            const predecessor = edge_source[edge_index];
            if (status[predecessor] == 0) {
                if (status[resolved] == 2) {
                    status[predecessor] = 1;
                    queue[count] = predecessor;
                    count += 1;
                } else {
                    remaining[predecessor] -= 1;
                    if (remaining[predecessor] == 0) {
                        status[predecessor] = 2;
                        queue[count] = predecessor;
                        count += 1;
                    }
                }
            }
            edge = edge_next[edge_index];
        }
    }
    staged[0] = @intCast(n);
    for (0..n) |vertex| staged[vertex + 1] = status[vertex];
    const needed = n + 1;
    if (output == null or capacity < needed) return -2;
    for (0..needed) |index| output[index] = staged[index];
    return @intCast(needed);
}
