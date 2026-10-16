const MAX_VERTICES: usize = 14;
const AUGMENTED_VERTICES: usize = 16;
const MAX_INPUT_LENGTH: usize = 227;
const MAX_CAPACITY: i64 = 1_000_000;

pub export fn push_relabel(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const n64 = input[0];
    const source_count64 = input[1];
    if (n64 < 2 or n64 > MAX_VERTICES or source_count64 < 1 or source_count64 >= n64) return -1;
    const n: usize = @intCast(n64);
    const source_count: usize = @intCast(source_count64);
    const sink_count_index = 2 + source_count;
    if (length <= sink_count_index) return -1;

    var is_source: [MAX_VERTICES]bool = @splat(false);
    var is_sink: [MAX_VERTICES]bool = @splat(false);
    var sources: [MAX_VERTICES]usize = @splat(0);
    for (0..source_count) |index| {
        const node64 = input[2 + index];
        if (node64 < 0 or node64 >= n64) return -1;
        const node: usize = @intCast(node64);
        if (is_source[node]) return -1;
        sources[index] = node;
        is_source[node] = true;
    }
    const sink_count64 = input[sink_count_index];
    if (sink_count64 < 1 or sink_count64 > n64 - source_count64) return -1;
    const sink_count: usize = @intCast(sink_count64);
    const matrix_start = sink_count_index + 1 + sink_count;
    if (length < matrix_start or length != matrix_start + n * n) return -1;
    for (0..sink_count) |index| {
        const node64 = input[sink_count_index + 1 + index];
        if (node64 < 0 or node64 >= n64) return -1;
        const node: usize = @intCast(node64);
        if (is_sink[node] or is_source[node]) return -1;
        is_sink[node] = true;
    }

    var residual: [AUGMENTED_VERTICES * AUGMENTED_VERTICES]i64 = @splat(0);
    var source_out: [MAX_VERTICES]i64 = @splat(0);
    var flow_limit: i64 = 0;
    for (0..n) |row| {
        for (0..n) |column| {
            const capacity = input[matrix_start + row * n + column];
            if (capacity < 0 or capacity > MAX_CAPACITY or (row == column and capacity != 0)) return -1;
            residual[row * AUGMENTED_VERTICES + column] = capacity;
            if (is_source[row]) {
                source_out[row] += capacity;
                flow_limit += capacity;
            }
        }
    }

    const super_source = n;
    const super_sink = n + 1;
    for (0..source_count) |index| {
        residual[super_source * AUGMENTED_VERTICES + sources[index]] = source_out[sources[index]];
    }
    for (0..sink_count) |index| {
        const sink: usize = @intCast(input[sink_count_index + 1 + index]);
        residual[sink * AUGMENTED_VERTICES + super_sink] = flow_limit;
    }

    var height: [AUGMENTED_VERTICES]i32 = @splat(0);
    var excess: [AUGMENTED_VERTICES]i64 = @splat(0);
    var active: [AUGMENTED_VERTICES]bool = @splat(false);
    height[super_source] = @intCast(n + 2);
    for (0..source_count) |index| {
        const source = sources[index];
        const initial_excess = residual[super_source * AUGMENTED_VERTICES + source];
        residual[super_source * AUGMENTED_VERTICES + source] = 0;
        residual[source * AUGMENTED_VERTICES + super_source] += initial_excess;
        excess[source] += initial_excess;
        if (excess[source] > 0) active[source] = true;
    }

    while (true) {
        var node: usize = 0;
        while (node < n and !active[node]) : (node += 1) {}
        if (node == n) break;
        active[node] = false;
        while (excess[node] > 0) {
            var pushed = false;
            for (0..n + 2) |neighbor| {
                if (excess[node] == 0) break;
                const edge = node * AUGMENTED_VERTICES + neighbor;
                if (residual[edge] <= 0 or height[node] != height[neighbor] + 1) continue;
                const amount = @min(excess[node], residual[edge]);
                residual[edge] -= amount;
                residual[neighbor * AUGMENTED_VERTICES + node] += amount;
                excess[node] -= amount;
                const previous_excess = excess[neighbor];
                excess[neighbor] += amount;
                if (neighbor < n and previous_excess == 0) active[neighbor] = true;
                pushed = true;
            }
            if (excess[node] > 0 and !pushed) {
                var minimum_height: i32 = 1000;
                for (0..n + 2) |neighbor| {
                    if (residual[node * AUGMENTED_VERTICES + neighbor] > 0)
                        minimum_height = @min(minimum_height, height[neighbor]);
                }
                if (minimum_height == 1000) return -1;
                height[node] = minimum_height + 1;
            }
        }
    }
    return excess[super_sink];
}
