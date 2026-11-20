const MAX_PARSEABLE_INPUT: usize = 117;
const OUTPUT_BYTES: usize = 16;

fn socShortestPath(adjacency: [8]u16, n: usize, source: usize,
    target: usize) [9]usize {
    var result: [9]usize = .{0} ** 9;
    var distance: [8]i32 = .{-1} ** 8;
    var predecessor: [8]usize = .{0} ** 8;
    var hasPredecessor: [8]bool = .{false} ** 8;
    var queue: [8]usize = .{0} ** 8;
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = source;
    distance[source] = 0;
    while (head < tail) {
        const vertex = queue[head];
        head += 1;
        for (0..n) |successor| {
            const bit: u16 = @as(u16, 1) << @intCast(successor);
            if ((adjacency[vertex] & bit) != 0 and distance[successor] == -1) {
                distance[successor] = distance[vertex] + 1;
                predecessor[successor] = vertex;
                hasPredecessor[successor] = true;
                queue[tail] = successor;
                tail += 1;
            }
        }
    }
    if (distance[target] == -1) return result;
    var reversed: [8]usize = .{0} ** 8;
    var count: usize = 0;
    var vertex = target;
    while (true) {
        reversed[count] = vertex;
        count += 1;
        if (vertex == source) break;
        if (!hasPredecessor[vertex]) return result;
        vertex = predecessor[vertex];
    }
    result[0] = count;
    for (0..count) |index| result[index + 1] = reversed[count - index - 1];
    return result;
}

fn socGcd(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn socWriteI64(output: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn network_erosion_strength_of_connection(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 4 or length > MAX_PARSEABLE_INPUT) return -1;
    const vertex_raw = input[0];
    const edge_raw = input[1];
    const source_raw = input[2];
    const target_raw = input[3];
    if (vertex_raw < 2 or vertex_raw > 8 or edge_raw < 0 or
        edge_raw > vertex_raw * (vertex_raw - 1) or source_raw < 0 or source_raw >= vertex_raw or
        target_raw < 0 or target_raw >= vertex_raw or source_raw == target_raw) return -1;
    const n: usize = @intCast(vertex_raw);
    const edge_count: usize = @intCast(edge_raw);
    const source: usize = @intCast(source_raw);
    const target: usize = @intCast(target_raw);
    if (length != 4 + 2 * edge_count) return -1;

    var adjacency: [8]u16 = .{0} ** 8;
    var cursor: usize = 4;
    for (0..edge_count) |_| {
        const from_raw = input[cursor];
        const to_raw = input[cursor + 1];
        cursor += 2;
        if (from_raw < 0 or from_raw >= vertex_raw or to_raw < 0 or to_raw >= vertex_raw or from_raw == to_raw) return -1;
        const from: usize = @intCast(from_raw);
        const to: usize = @intCast(to_raw);
        const bit: u16 = @as(u16, 1) << @intCast(to);
        if ((adjacency[from] & bit) != 0) return -1;
        adjacency[from] |= bit;
    }

    var distances: [8]i32 = .{-1} ** 8;
    const first = socShortestPath(adjacency, n, source, target);
    if (first[0] != 0) {
        const initial_length: i32 = @intCast(first[0] - 1);
        distances[source] = initial_length;
        distances[target] = initial_length;
        while (true) {
            const current = socShortestPath(adjacency, n, source, target);
            const path_count = current[0];
            if (path_count == 0) break;
            const path_length: i32 = @intCast(path_count - 1);
            if (path_length == 1) {
                adjacency[source] &= ~(@as(u16, 1) << @intCast(target));
                continue;
            }
            for (0..path_count) |index| {
                const vertex = current[index + 1];
                if (distances[vertex] == -1) distances[vertex] = path_length;
            }
            for (1..path_count - 1) |index| {
                const vertex = current[index + 1];
                const bit: u16 = @as(u16, 1) << @intCast(vertex);
                adjacency[vertex] = 0;
                for (0..n) |other| adjacency[other] &= ~bit;
            }
        }
    }

    var reciprocal_sum_scaled: i64 = 0;
    for (0..n) |vertex| {
        if (distances[vertex] >= 1) reciprocal_sum_scaled += @divTrunc(420, distances[vertex]);
    }
    var numerator = 2 * reciprocal_sum_scaled;
    var denominator: i64 = 420 * (@as(i64, @intCast(n)) + 2);
    if (numerator == 0) {
        denominator = 1;
    } else {
        const divisor = socGcd(numerator, denominator);
        numerator = @divTrunc(numerator, divisor);
        denominator = @divTrunc(denominator, divisor);
    }
    const output = output_opt orelse return -2;
    if (capacity < OUTPUT_BYTES) return -2;
    socWriteI64(output, 0, numerator);
    socWriteI64(output, 1, denominator);
    return OUTPUT_BYTES;
}
