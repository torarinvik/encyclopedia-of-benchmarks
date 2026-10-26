const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT: usize = 66;
const MAX_FIELDS: usize = 73;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_FIELDS;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn uniqueShortestPaths(adjacency: *const [MAX_VERTICES * MAX_VERTICES]bool, n: usize) bool {
    for (0..n) |source| {
        var distance: [MAX_VERTICES]i16 = @splat(-1);
        var ways: [MAX_VERTICES]u8 = @splat(0);
        var queue: [MAX_VERTICES]usize = @splat(0);
        var head: usize = 0;
        var tail: usize = 0;
        distance[source] = 0;
        ways[source] = 1;
        queue[tail] = source;
        tail += 1;
        while (head < tail) {
            const vertex = queue[head];
            head += 1;
            for (0..n) |neighbor| {
                if (!adjacency.*[vertex * MAX_VERTICES + neighbor]) continue;
                if (distance[neighbor] < 0) {
                    distance[neighbor] = distance[vertex] + 1;
                    ways[neighbor] = ways[vertex];
                    queue[tail] = neighbor;
                    tail += 1;
                } else if (distance[neighbor] == distance[vertex] + 1) {
                    const sum = @as(usize, ways[neighbor]) + @as(usize, ways[vertex]);
                    ways[neighbor] = @intCast(@min(2, sum));
                }
            }
        }
        for (0..n) |vertex| if (ways[vertex] != 1) return false;
    }
    return true;
}

export fn hub_labeling_pruned(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, MAX_VERTICES)
        or input[1] < 0 or input[1] > @as(i64, MAX_EDGES)) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + 2 * m) return -1;
    var seen_order: [MAX_VERTICES]bool = @splat(false);
    for (0..n) |i| {
        const vertex = input[2 + i];
        if (vertex < 0 or vertex >= @as(i64, @intCast(n))) return -1;
        const index: usize = @intCast(vertex);
        if (seen_order[index]) return -1;
        seen_order[index] = true;
    }
    var adjacency: [MAX_VERTICES * MAX_VERTICES]bool = @splat(false);
    var previous_left: i64 = -1;
    var previous_right: i64 = -1;
    for (0..m) |edge| {
        const left = input[2 + n + 2 * edge];
        const right = input[3 + n + 2 * edge];
        if (left < 0 or right <= left or right >= @as(i64, @intCast(n)) or left < previous_left
            or (left == previous_left and right <= previous_right)) return -1;
        previous_left = left;
        previous_right = right;
        const u: usize = @intCast(left);
        const v: usize = @intCast(right);
        adjacency[u * MAX_VERTICES + v] = true;
        adjacency[v * MAX_VERTICES + u] = true;
    }
    if (!uniqueShortestPaths(&adjacency, n)) return -1;

    var labels: [MAX_VERTICES * MAX_VERTICES]i16 = @splat(-1);
    for (0..n) |order_index| {
        const hub: usize = @intCast(input[2 + order_index]);
        var distance: [MAX_VERTICES]i16 = @splat(-1);
        var queue: [MAX_VERTICES]usize = @splat(0);
        var head: usize = 0;
        var tail: usize = 0;
        distance[hub] = 0;
        queue[tail] = hub;
        tail += 1;
        while (head < tail) {
            const vertex = queue[head];
            head += 1;
            var estimate: i16 = 2 * @as(i16, @intCast(MAX_VERTICES));
            for (0..n) |common| {
                const from_hub = labels[hub * MAX_VERTICES + common];
                const from_vertex = labels[vertex * MAX_VERTICES + common];
                if (from_hub >= 0 and from_vertex >= 0 and from_hub + from_vertex < estimate)
                    estimate = from_hub + from_vertex;
            }
            if (estimate <= distance[vertex]) continue;
            labels[vertex * MAX_VERTICES + hub] = distance[vertex];
            for (0..n) |neighbor| {
                if (adjacency[vertex * MAX_VERTICES + neighbor] and distance[neighbor] < 0) {
                    distance[neighbor] = distance[vertex] + 1;
                    queue[tail] = neighbor;
                    tail += 1;
                }
            }
        }
    }
    var fields: [MAX_FIELDS]i64 = @splat(0);
    var field_count: usize = 0;
    fields[field_count] = @intCast(n);
    field_count += 1;
    for (0..n) |vertex| {
        const count_index = field_count;
        field_count += 1;
        var count: i64 = 0;
        for (0..n) |hub| {
            const value = labels[vertex * MAX_VERTICES + hub];
            if (value >= 0) {
                fields[field_count] = @as(i64, @intCast(hub)) | (@as(i64, value) << 8);
                field_count += 1;
                count += 1;
            }
        }
        fields[count_index] = count;
    }
    const bytes = field_count * 8;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..field_count) |i| storeI64Le(&staged, 8 * i, fields[i]);
    for (0..bytes) |i| output[i] = staged[i];
    return @intCast(bytes);
}
