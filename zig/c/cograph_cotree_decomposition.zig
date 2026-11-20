// Bounded clean-room connected/co-connected cograph cotree profile.
const N: usize = 12;
const M: usize = 66;
const parseable: usize = 135;
const output_cap: usize = 47;

fn components(mask: u16, adjacency: *const [N]u16, complement: bool,
              parts: *[N]u16) usize {
    var remaining = mask;
    var count: usize = 0;
    for (0..N) |root| {
        const root_bit: u16 = @as(u16, 1) << @as(u4, @intCast(root));
        if (remaining & root_bit == 0) continue;
        var reached = root_bit;
        var queue: [N]usize = undefined;
        queue[0] = root;
        var head: usize = 0;
        var tail: usize = 1;
        while (head < tail) : (head += 1) {
            const vertex = queue[head];
            var neighbors = adjacency[vertex] & mask;
            if (complement)
                neighbors = mask & ~adjacency[vertex] & ~( @as(u16, 1) << @as(u4, @intCast(vertex)) );
            var fresh = neighbors & ~reached;
            for (0..N) |next| {
                const bit: u16 = @as(u16, 1) << @as(u4, @intCast(next));
                if (fresh & bit != 0) {
                    fresh &= ~bit;
                    reached |= bit;
                    queue[tail] = next;
                    tail += 1;
                }
            }
        }
        parts[count] = reached;
        count += 1;
        remaining &= ~reached;
    }
    return count;
}

fn emit(mask: u16, adjacency: *const [N]u16, output: *[output_cap]u8,
        position: *usize) bool {
    if (mask & (mask - 1) == 0) {
        output[position.*] = 0;
        output[position.* + 1] = @intCast(@ctz(mask));
        position.* += 2;
        return true;
    }
    var parts: [N]u16 = undefined;
    var count = components(mask, adjacency, false, &parts);
    var kind: u8 = 1;
    if (count == 1) {
        count = components(mask, adjacency, true, &parts);
        kind = 2;
        if (count <= 1) return false;
    }
    output[position.*] = kind;
    output[position.* + 1] = @intCast(count);
    position.* += 2;
    for (0..count) |i| if (!emit(parts[i], adjacency, output, position)) return false;
    return true;
}

export fn cograph_cotree_decomposition(input: ?[*]const i64, length: usize,
                                        output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > parseable) return -1;
    const values = input.?;
    const n64 = values[0];
    const m64 = values[1];
    if (n64 < 1 or n64 > N or m64 < 0 or m64 > M or m64 > n64 * (n64 - 1) / 2 or
        length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacency = [_]u16{0} ** N;
    for (0..m) |edge| {
        const u64 = values[2 + 2 * edge];
        const v64 = values[3 + 2 * edge];
        if (u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        const ub: u16 = @as(u16, 1) << @as(u4, @intCast(u));
        const vb: u16 = @as(u16, 1) << @as(u4, @intCast(v));
        if (adjacency[u] & vb != 0) return -1;
        adjacency[u] |= vb;
        adjacency[v] |= ub;
    }
    var staged: [output_cap]u8 = [_]u8{0} ** output_cap;
    var output_length: usize = 1;
    if (emit((@as(u16, 1) << @as(u4, @intCast(n))) - 1, &adjacency, &staged, &output_length)) {
        staged[0] = 1;
    } else {
        staged[0] = 0;
        output_length = 1;
    }
    if (output == null or capacity < output_length) return -2;
    for (0..output_length) |i| output.?[i] = staged[i];
    return @intCast(output_length);
}
