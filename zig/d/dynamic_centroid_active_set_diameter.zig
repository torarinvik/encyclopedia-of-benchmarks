const MAX_N: usize = 32;
const MAX_OPERATIONS: usize = 64;
const MAX_LEVELS: usize = 6;
const MAX_PARSEABLE_LENGTH: usize = 98;

const Record = struct {
    centroid: usize,
    branch: usize,
    distance: usize,
};

const Context = struct {
    n: usize,
    adjacency: [MAX_N * MAX_N]bool,
    blocked: [MAX_N]bool,
    subtree_size: [MAX_N]usize,
    records: [MAX_N * MAX_LEVELS]Record,
    record_count: [MAX_N]usize,

    fn componentSize(self: *Context, vertex: usize, parent: usize) usize {
        var total: usize = 1;
        for (0..self.n) |neighbor| {
            if (self.adjacency[vertex * self.n + neighbor]
                and neighbor != parent and !self.blocked[neighbor])
            {
                total += self.componentSize(neighbor, vertex);
            }
        }
        self.subtree_size[vertex] = total;
        return total;
    }

    fn chooseCentroid(self: *const Context, vertex: usize, parent: usize, total: usize) usize {
        for (0..self.n) |neighbor| {
            if (self.adjacency[vertex * self.n + neighbor]
                and neighbor != parent and !self.blocked[neighbor]
                and self.subtree_size[neighbor] > total / 2)
            {
                return self.chooseCentroid(neighbor, vertex, total);
            }
        }
        return vertex;
    }

    fn recordComponent(self: *Context, centroid: usize, vertex: usize, parent: usize,
        distance: usize, branch: usize, level: usize) void
    {
        if (level >= MAX_LEVELS) return;
        const index = vertex * MAX_LEVELS + level;
        self.records[index] = .{
            .centroid = centroid,
            .branch = if (vertex == centroid) self.n else branch,
            .distance = distance,
        };
        self.record_count[vertex] = level + 1;
        for (0..self.n) |neighbor| {
            if (self.adjacency[vertex * self.n + neighbor]
                and neighbor != parent and !self.blocked[neighbor])
            {
                const next_branch = if (vertex == centroid) neighbor else branch;
                self.recordComponent(centroid, neighbor, vertex, distance + 1,
                    next_branch, level);
            }
        }
    }

    fn buildCentroids(self: *Context, entry: usize, level: usize) void {
        if (level >= MAX_LEVELS) return;
        const total = self.componentSize(entry, MAX_N);
        const centroid = self.chooseCentroid(entry, MAX_N, total);
        self.recordComponent(centroid, centroid, MAX_N, 0, self.n, level);
        self.blocked[centroid] = true;
        for (0..self.n) |neighbor| {
            if (self.adjacency[centroid * self.n + neighbor] and !self.blocked[neighbor]) {
                self.buildCentroids(neighbor, level + 1);
            }
        }
    }
};

fn recomputeBranch(context: *const Context, active: *const [MAX_N]bool,
    best: *[MAX_N * (MAX_N + 1)]i32, centroid: usize, branch: usize) void
{
    const bucket = centroid * (context.n + 1) + branch;
    best[bucket] = -1;
    for (0..context.n) |vertex| {
        if (!active[vertex]) continue;
        for (0..context.record_count[vertex]) |record_index| {
            const record = context.records[vertex * MAX_LEVELS + record_index];
            if (record.centroid == centroid and record.branch == branch) {
                best[bucket] = @max(best[bucket], @as(i32, @intCast(record.distance)));
            }
        }
    }
}

fn activeDiameter(n: usize, best: *const [MAX_N * (MAX_N + 1)]i32) i32 {
    var answer: i32 = 0;
    for (0..n) |centroid| {
        var first: i32 = -1;
        var second: i32 = -1;
        for (0..n + 1) |branch| {
            const distance = best[centroid * (n + 1) + branch];
            if (distance > first) {
                second = first;
                first = distance;
            } else if (distance > second) {
                second = distance;
            }
        }
        if (second >= 0) answer = @max(answer, first + second);
    }
    return answer;
}

export fn dynamic_centroid_active_set_diameter(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const operation_count_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N))
        or operation_count_value < 0
        or operation_count_value > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const n: usize = @intCast(n_value);
    const operation_count: usize = @intCast(operation_count_value);
    if (length != n + 1 + operation_count) return -1;

    var context = Context{
        .n = n,
        .adjacency = [_]bool{false} ** (MAX_N * MAX_N),
        .blocked = [_]bool{false} ** MAX_N,
        .subtree_size = [_]usize{0} ** MAX_N,
        .records = [_]Record{.{ .centroid = 0, .branch = 0, .distance = 0 }}
            ** (MAX_N * MAX_LEVELS),
        .record_count = [_]usize{0} ** MAX_N,
    };
    for (1..n) |vertex| {
        const parent_value = input[vertex + 1];
        if (parent_value < 0 or parent_value >= @as(i64, @intCast(vertex))) return -1;
        const parent: usize = @intCast(parent_value);
        context.adjacency[parent * n + vertex] = true;
        context.adjacency[vertex * n + parent] = true;
    }
    for (0..operation_count) |offset| {
        const operation = input[n + 1 + offset];
        if (operation != -1 and (operation < 0 or operation >= @as(i64, @intCast(n)))) return -1;
    }

    context.buildCentroids(0, 0);
    var best = [_]i32{-1} ** (MAX_N * (MAX_N + 1));
    var active = [_]bool{false} ** MAX_N;
    var checksum: i64 = 0;
    var query_number: i64 = 0;
    for (0..operation_count) |offset| {
        const operation = input[n + 1 + offset];
        if (operation == -1) {
            query_number += 1;
            checksum += query_number * @as(i64, @intCast(activeDiameter(n, &best) + 1));
            continue;
        }
        const vertex: usize = @intCast(operation);
        active[vertex] = !active[vertex];
        for (0..context.record_count[vertex]) |record_index| {
            const record = context.records[vertex * MAX_LEVELS + record_index];
            const bucket = record.centroid * (n + 1) + record.branch;
            const distance: i32 = @intCast(record.distance);
            if (active[vertex]) {
                best[bucket] = @max(best[bucket], distance);
            } else if (best[bucket] == distance) {
                recomputeBranch(&context, &active, &best, record.centroid, record.branch);
            }
        }
    }
    return checksum;
}
