const MAX_N: usize = 32;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 131;
const MAX_OUTPUT: usize = 1592;

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tree_decomposition_width_2(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64, const m64 = .{ input[0], input[1] };
    if (n64 < 1 or n64 > MAX_N or m64 < 0 or m64 > MAX_M) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (m > n * (n - 1) / 2 or length != 2 + 2 * m) return -1;

    var adjacent: [MAX_N][MAX_N]bool = @splat(@splat(false));
    for (0..m) |edge| {
        const left64, const right64 = .{ input[2 + 2 * edge], input[3 + 2 * edge] };
        if (left64 < 0 or left64 >= right64 or right64 >= n64) return -1;
        const left: usize = @intCast(left64);
        const right: usize = @intCast(right64);
        if (adjacent[left][right]) return -1;
        adjacent[left][right] = true;
        adjacent[right][left] = true;
    }

    var active: [MAX_N]bool = @splat(false);
    for (0..n) |vertex| active[vertex] = true;
    var order: [MAX_N]usize = @splat(0);
    var bags: [MAX_N][3]i64 = @splat(@splat(-1));
    var bag_sizes: [MAX_N]usize = @splat(0);
    var later: [MAX_N][2]usize = @splat(@splat(0));
    var later_counts: [MAX_N]usize = @splat(0);
    var position: [MAX_N]usize = @splat(0);

    for (0..n) |step| {
        var chosen: ?usize = null;
        var neighbors: [2]usize = @splat(0);
        var count: usize = 0;
        for (0..n) |vertex| {
            if (!active[vertex]) continue;
            var degree: usize = 0;
            for (0..n) |other| {
                if (active[other] and adjacent[vertex][other]) degree += 1;
            }
            if (degree <= 2) {
                chosen = vertex;
                for (0..n) |other| {
                    if (active[other] and adjacent[vertex][other]) {
                        neighbors[count] = other;
                        count += 1;
                    }
                }
                break;
            }
        }
        if (chosen == null) return -1;
        const vertex = chosen.?;
        order[step] = vertex;
        later_counts[step] = count;
        bag_sizes[step] = count + 1;
        bags[step][0] = @intCast(vertex);
        for (0..count) |index| {
            later[step][index] = neighbors[index];
            bags[step][index + 1] = @intCast(neighbors[index]);
        }
        for (0..(count + 1)) |i| {
            for ((i + 1)..(count + 1)) |j| {
                if (bags[step][j] < bags[step][i]) {
                    const temporary = bags[step][i];
                    bags[step][i] = bags[step][j];
                    bags[step][j] = temporary;
                }
            }
        }
        if (count == 2) {
            adjacent[neighbors[0]][neighbors[1]] = true;
            adjacent[neighbors[1]][neighbors[0]] = true;
        }
        active[vertex] = false;
    }

    for (0..n) |step| position[order[step]] = step;
    var parents: [MAX_N]usize = @splat(n);
    for (0..n) |step| {
        if (later_counts[step] > 0) {
            var selected = later[step][0];
            if (later_counts[step] == 2 and position[later[step][1]] < position[selected])
                selected = later[step][1];
            parents[step] = position[selected];
        }
    }

    const bytes = 8 * (6 * n + 7);
    if (output_opt == null or capacity < bytes or bytes > MAX_OUTPUT) return -2;
    var staged: [MAX_OUTPUT]u8 = @splat(0);
    putI64(&staged, 0, @intCast(n + 1));
    putI64(&staged, 8, 2);
    putI64(&staged, 16, @intCast(n));
    var cursor: usize = 24;
    for (0..n + 1) |bag| {
        const size: usize = if (bag == n) 0 else bag_sizes[bag];
        putI64(&staged, cursor, @intCast(size));
        cursor += 8;
        for (0..3) |slot| {
            const value: i64 = if (slot < size) bags[bag][slot] else -1;
            putI64(&staged, cursor, value);
            cursor += 8;
        }
    }
    for (0..n) |child| {
        putI64(&staged, cursor, @intCast(child));
        putI64(&staged, cursor + 8, @intCast(parents[child]));
        cursor += 16;
    }
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
