const MAX_NODES: usize = 256;
const DX = [_]i32{-1, -1, -1, 0, 0, 1, 1, 1};
const DY = [_]i32{-1, 0, 1, -1, 1, -1, 0, 1};

const SearchNode = struct { x: i32, y: i32, g: i32, f: i32, parent: i32 };

fn writeI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| {
        output[offset + i] = @truncate(bits >> @intCast(i * 8));
    }
}

pub export fn astar(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 6) return -1;
    const rows64 = input[0];
    const cols64 = input[1];
    const sx64 = input[2];
    const sy64 = input[3];
    const gx64 = input[4];
    const gy64 = input[5];
    if (rows64 < 1 or rows64 > 16 or cols64 < 1 or cols64 > 16 or
        sx64 < 0 or sx64 >= rows64 or sy64 < 0 or sy64 >= cols64 or
        gx64 < 0 or gx64 >= rows64 or gy64 < 0 or gy64 >= cols64) return -1;
    const rows: i32 = @intCast(rows64);
    const cols: i32 = @intCast(cols64);
    const sx: i32 = @intCast(sx64);
    const sy: i32 = @intCast(sy64);
    const gx: i32 = @intCast(gx64);
    const gy: i32 = @intCast(gy64);
    var nodes: [MAX_NODES]SearchNode = undefined;
    var open: [MAX_NODES]i32 = undefined;
    var node_count: usize = 1;
    var open_count: usize = 1;
    nodes[0] = .{ .x = sx, .y = sy, .g = 0, .f = 0, .parent = -1 };
    open[0] = 0;
    var current: i32 = 0;
    var found = false;
    while (open_count > 0) {
        var best: usize = 0;
        for (1..open_count) |i| {
            if (nodes[@intCast(open[i])].f < nodes[@intCast(open[best])].f) best = i;
        }
        current = open[best];
        for (best + 1..open_count) |i| open[i - 1] = open[i];
        open_count -= 1;
        const current_node = nodes[@intCast(current)];
        if (current_node.x == gx and current_node.y == gy) {
            found = true;
            break;
        }
        for (0..8) |neighbor| {
            const x = current_node.x + DX[neighbor];
            const y = current_node.y + DY[neighbor];
            if (x < 0 or x >= rows or y < 0 or y >= cols) continue;
            if (node_count >= MAX_NODES or open_count >= MAX_NODES) return -1;
            const g = current_node.g + 1;
            const ex = gx - x;
            const ey = gy - y;
            nodes[node_count] = .{ .x = x, .y = y, .g = g, .f = g + ex * ex + ey * ey, .parent = current };
            open[open_count] = @intCast(node_count);
            open_count += 1;
            node_count += 1;
        }
    }
    if (!found) return -1;
    var path_count: usize = 0;
    var cursor = current;
    while (cursor >= 0) {
        path_count += 1;
        cursor = nodes[@intCast(cursor)].parent;
    }
    const output_bytes = path_count * 16;
    if (output == null or capacity < output_bytes) return -2;
    var offset = output_bytes;
    cursor = current;
    while (cursor >= 0) {
        offset -= 16;
        const node = nodes[@intCast(cursor)];
        writeI64(output, offset, node.x);
        writeI64(output, offset + 8, node.y);
        cursor = node.parent;
    }
    return @intCast(output_bytes);
}
