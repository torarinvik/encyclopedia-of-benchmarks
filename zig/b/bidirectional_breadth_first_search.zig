const MAX_DIMENSION: usize = 8;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const MAX_INPUT_LENGTH: usize = 5 + MAX_CELLS;
const MAX_OUTPUT_VALUES: usize = 1 + MAX_CELLS;

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

pub export fn bidirectional_breadth_first_search(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const rows_value = input[0];
    const cols_value = input[1];
    if (rows_value < 1 or rows_value > MAX_DIMENSION or cols_value < 1 or cols_value > MAX_DIMENSION) return -1;
    const rows: usize = @intCast(rows_value);
    const cols: usize = @intCast(cols_value);
    const cells = rows * cols;
    const start_value = input[2];
    const goal_value = input[3];
    const blocked_count_value = input[4];
    if (start_value < 0 or start_value >= @as(i64, @intCast(cells)) or goal_value < 0 or goal_value >= @as(i64, @intCast(cells))
        or blocked_count_value < 0 or blocked_count_value > @as(i64, @intCast(cells))) return -1;
    const blocked_count: usize = @intCast(blocked_count_value);
    if (length != 5 + blocked_count) return -1;
    const start: usize = @intCast(start_value);
    const goal: usize = @intCast(goal_value);
    var blocked: [MAX_CELLS]bool = @splat(false);
    for (0..blocked_count) |index| {
        const value = input[5 + index];
        if (value < 0 or value >= @as(i64, @intCast(cells))) return -1;
        const cell: usize = @intCast(value);
        if (blocked[cell]) return -1;
        blocked[cell] = true;
    }
    if (blocked[start] or blocked[goal]) return -1;

    var distance: [2 * MAX_CELLS]i64 = undefined;
    var parent: [2 * MAX_CELLS]i64 = undefined;
    for (0..2 * MAX_CELLS) |index| { distance[index] = -1; parent[index] = -1; }
    var queues: [2 * MAX_CELLS]usize = undefined;
    var head: [2]usize = @splat(0);
    var tail: [2]usize = @splat(1);
    distance[start] = 0;
    distance[MAX_CELLS + goal] = 0;
    queues[0] = start;
    queues[MAX_CELLS] = goal;
    var meeting: ?usize = if (start == goal) start else null;
    while (meeting == null and head[0] < tail[0] and head[1] < tail[1]) {
      for (0..2) |side| {
        if (meeting != null) break;
        const layer_end = tail[side];
        while (head[side] < layer_end) {
            const node = queues[side * MAX_CELLS + head[side]];
            head[side] += 1;
            const row = node / cols;
            const col = node % cols;
            var neighbors: [4]usize = .{ MAX_CELLS, MAX_CELLS, MAX_CELLS, MAX_CELLS };
            if (row > 0) neighbors[0] = node - cols;
            if (col > 0) neighbors[1] = node - 1;
            if (row + 1 < rows) neighbors[2] = node + cols;
            if (col + 1 < cols) neighbors[3] = node + 1;
            for (neighbors) |neighbor| {
                if (neighbor == MAX_CELLS or blocked[neighbor] or distance[side * MAX_CELLS + neighbor] >= 0) continue;
                distance[side * MAX_CELLS + neighbor] = distance[side * MAX_CELLS + node] + 1;
                parent[side * MAX_CELLS + neighbor] = @intCast(node);
                queues[side * MAX_CELLS + tail[side]] = neighbor;
                tail[side] += 1;
                if (distance[(1 - side) * MAX_CELLS + neighbor] >= 0) { meeting = neighbor; break; }
            }
            if (meeting != null) break;
        }
      }
    }
    var encoded: [MAX_OUTPUT_VALUES]i64 = @splat(0);
    var value_count: usize = 1;
    if (meeting) |meeting_cell| {
        var reverse_path: [MAX_CELLS]usize = undefined;
        var prefix_count: usize = 0;
        var current: i64 = @intCast(meeting_cell);
        while (current >= 0) {
            reverse_path[prefix_count] = @intCast(current);
            prefix_count += 1;
            if (@as(usize, @intCast(current)) == start) break;
            current = parent[@intCast(current)];
        }
        var path_count: usize = 0;
        for (0..prefix_count) |index| {
            encoded[1 + path_count] = @intCast(reverse_path[prefix_count - 1 - index]);
            path_count += 1;
        }
        current = parent[MAX_CELLS + meeting_cell];
        while (current >= 0) {
            encoded[1 + path_count] = current;
            path_count += 1;
            current = parent[MAX_CELLS + @as(usize, @intCast(current))];
        }
        encoded[0] = @intCast(path_count);
        value_count += path_count;
    } else {
        encoded[0] = 0;
    }
    const required = value_count * 8;
    if (output == null or capacity < required) return -2;
    for (0..value_count) |index| putI64(output, index * 8, encoded[index]);
    return @intCast(required);
}
