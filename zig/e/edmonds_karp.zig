const MAX_VERTICES: usize = 16;
const MAX_CAPACITY: i64 = 1_000_000;

pub export fn edmonds_karp(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3) return -1;
    const n64 = input[0];
    const source64 = input[1];
    const sink64 = input[2];
    if (n64 < 1 or n64 > MAX_VERTICES or source64 < 0 or source64 >= n64 or sink64 < 0 or sink64 >= n64) return -1;
    const n: usize = @intCast(n64);
    if (length != 3 + n * n) return -1;

    var residual: [MAX_VERTICES * MAX_VERTICES]i64 = @splat(0);
    for (0..n) |row| {
        for (0..n) |column| {
            const capacity = input[3 + row * n + column];
            if (capacity < 0 or capacity > MAX_CAPACITY or (row == column and capacity != 0)) return -1;
            residual[row * n + column] = capacity;
        }
    }
    for (0..n) |left| {
        for (left + 1..n) |right| {
            if (residual[left * n + right] > 0 and residual[right * n + left] > 0) return -1;
        }
    }

    const source: usize = @intCast(source64);
    const sink: usize = @intCast(sink64);
    if (source == sink) return 0;
    var total_flow: i64 = 0;
    while (true) {
        var parent: [MAX_VERTICES]i32 = @splat(-1);
        var queue: [MAX_VERTICES]usize = undefined;
        parent[source] = @intCast(source);
        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = source;
        while (head < tail and parent[sink] == -1) {
            const node = queue[head];
            head += 1;
            for (0..n) |neighbor| {
                if (residual[node * n + neighbor] <= 0 or parent[neighbor] != -1) continue;
                parent[neighbor] = @intCast(node);
                if (neighbor == sink) break;
                queue[tail] = neighbor;
                tail += 1;
            }
        }
        if (parent[sink] == -1) return total_flow;
        var path_flow: i64 = MAX_CAPACITY;
        var node = sink;
        while (node != source) {
            const previous: usize = @intCast(parent[node]);
            path_flow = @min(path_flow, residual[previous * n + node]);
            node = previous;
        }
        node = sink;
        while (node != source) {
            const previous: usize = @intCast(parent[node]);
            residual[previous * n + node] -= path_flow;
            residual[node * n + previous] += path_flow;
            node = previous;
        }
        total_flow += path_flow;
    }
}
