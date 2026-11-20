const MAX_OPERATIONS: i64 = 64;
const MAX_ITEMS: usize = 32;
const MAX_NODES: usize = 64;
const MAX_KEY: i64 = 1_000_000;

const Node = struct {
    key: i64 = 0,
    serial: i64 = 0,
    item_id: i32 = -1,
    rank: i32 = 0,
    first_child: i32 = -1,
    next_sibling: i32 = -1,
    parent: i32 = -2,
    alive: bool = false,
};

const Queue = struct {
    nodes: [MAX_NODES]Node = @splat(.{}),
    active: [MAX_ITEMS]bool = @splat(false),
    node_count: usize = 0,
    next_serial: i64 = 0,

    fn less(self: *const Queue, first: i32, second: i32) bool {
        const a = self.nodes[@intCast(first)];
        const b = self.nodes[@intCast(second)];
        if (a.key != b.key) return a.key < b.key;
        if (a.serial != b.serial) return a.serial < b.serial;
        if (a.item_id != b.item_id) return a.item_id < b.item_id;
        return first < second;
    }

    fn rootBefore(self: *const Queue, first: i32, second: i32) bool {
        const a = self.nodes[@intCast(first)];
        const b = self.nodes[@intCast(second)];
        if (a.rank != b.rank) return a.rank < b.rank;
        if (a.serial != b.serial) return a.serial < b.serial;
        return first < second;
    }

    fn collectRoots(self: *const Queue, roots: *[MAX_NODES]i32) usize {
        var count: usize = 0;
        for (0..self.node_count) |i| {
            if (self.nodes[i].alive and self.nodes[i].parent == -1) {
                const node: i32 = @intCast(i);
                var position = count;
                while (position > 0 and self.rootBefore(node, roots[position - 1])) {
                    roots[position] = roots[position - 1];
                    position -= 1;
                }
                roots[position] = node;
                count += 1;
            }
        }
        return count;
    }

    fn simpleLink(self: *Queue, first: i32, second: i32) i32 {
        var winner = first;
        var loser = second;
        if (!self.less(first, second)) { winner = second; loser = first; }
        const wi: usize = @intCast(winner);
        const li: usize = @intCast(loser);
        const old_children = self.nodes[wi].first_child;
        self.nodes[wi].first_child = loser;
        self.nodes[li].next_sibling = old_children;
        self.nodes[li].parent = winner;
        self.nodes[wi].rank += 1;
        return winner;
    }

    fn skewLink(self: *Queue, singleton: i32, first: i32, second: i32) void {
        const new_rank = self.nodes[@intCast(first)].rank + 1;
        var winner = first;
        var loser = second;
        if (self.less(singleton, first) and self.less(singleton, second)) {
            winner = singleton;
            const wi: usize = @intCast(winner);
            self.nodes[wi].first_child = first;
            self.nodes[@intCast(first)].next_sibling = second;
            self.nodes[@intCast(second)].next_sibling = -1;
            self.nodes[@intCast(first)].parent = winner;
            self.nodes[@intCast(second)].parent = winner;
        } else {
            if (!self.less(first, second)) { winner = second; loser = first; }
            const wi: usize = @intCast(winner);
            const li: usize = @intCast(loser);
            const si: usize = @intCast(singleton);
            const old_children = self.nodes[wi].first_child;
            self.nodes[wi].first_child = singleton;
            self.nodes[si].next_sibling = loser;
            self.nodes[li].next_sibling = old_children;
            self.nodes[si].parent = winner;
            self.nodes[li].parent = winner;
        }
        const wi: usize = @intCast(winner);
        self.nodes[wi].parent = -1;
        self.nodes[wi].rank = new_rank;
    }

    fn insertSingleton(self: *Queue, singleton: i32) void {
        const si: usize = @intCast(singleton);
        self.nodes[si].parent = -2;
        var roots: [MAX_NODES]i32 = @splat(0);
        const count = self.collectRoots(&roots);
        self.nodes[si].next_sibling = -1;
        if (count >= 2 and self.nodes[@intCast(roots[0])].rank == self.nodes[@intCast(roots[1])].rank) {
            self.skewLink(singleton, roots[0], roots[1]);
        } else {
            self.nodes[si].parent = -1;
        }
    }

    fn normalizeRoots(self: *Queue, roots: *[MAX_NODES]i32, count: usize) void {
        for (1..count) |i| {
            const key = roots[i];
            var position = i;
            while (position > 0 and self.rootBefore(key, roots[position - 1])) {
                roots[position] = roots[position - 1];
                position -= 1;
            }
            roots[position] = key;
        }
        var buckets: [MAX_NODES]i32 = @splat(-1);
        for (0..count) |i| {
            var current = roots[i];
            var rank: usize = @intCast(self.nodes[@intCast(current)].rank);
            while (buckets[rank] >= 0) {
                const previous = buckets[rank];
                buckets[rank] = -1;
                current = self.simpleLink(previous, current);
                rank = @intCast(self.nodes[@intCast(current)].rank);
            }
            buckets[rank] = current;
        }
    }

    fn minimumRoot(self: *const Queue) i32 {
        var best: i32 = -1;
        for (0..self.node_count) |i| {
            if (self.nodes[i].alive and self.nodes[i].parent == -1) {
                const node: i32 = @intCast(i);
                if (best < 0 or self.less(node, best)) best = node;
            }
        }
        return best;
    }

    fn deleteMin(self: *Queue, root: i32) void {
        var zero_rank: [MAX_NODES]i32 = @splat(0);
        var positive: [MAX_NODES]i32 = @splat(0);
        var zero_count: usize = 0;
        var positive_count: usize = 0;
        const ri: usize = @intCast(root);
        var child = self.nodes[ri].first_child;
        while (child >= 0) {
            const ci: usize = @intCast(child);
            const next = self.nodes[ci].next_sibling;
            self.nodes[ci].parent = -2;
            self.nodes[ci].next_sibling = -1;
            if (self.nodes[ci].rank == 0) {
                zero_rank[zero_count] = child;
                zero_count += 1;
            } else {
                positive[positive_count] = child;
                positive_count += 1;
            }
            child = next;
        }

        const item: usize = @intCast(self.nodes[ri].item_id);
        self.active[item] = false;
        self.nodes[ri].alive = false;
        self.nodes[ri].parent = -2;
        self.nodes[ri].item_id = -1;
        self.nodes[ri].first_child = -1;
        self.nodes[ri].next_sibling = -1;

        for (1..zero_count) |i| {
            const key = zero_rank[i];
            var position = i;
            while (position > 0) {
                const previous = zero_rank[position - 1];
                const pi: usize = @intCast(previous);
                const ki: usize = @intCast(key);
                if (self.nodes[pi].serial < self.nodes[ki].serial or (self.nodes[pi].serial == self.nodes[ki].serial and previous < key)) break;
                zero_rank[position] = previous;
                position -= 1;
            }
            zero_rank[position] = key;
        }

        var roots: [MAX_NODES]i32 = @splat(0);
        var root_count = self.collectRoots(&roots);
        for (0..positive_count) |i| {
            const node = positive[i];
            self.nodes[@intCast(node)].parent = -1;
            roots[root_count] = node;
            root_count += 1;
        }
        self.normalizeRoots(&roots, root_count);
        for (0..zero_count) |i| self.insertSingleton(zero_rank[i]);
    }
};

export fn skew_binomial_queue(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 194) return -1;
    const values = input.?[0..length];
    const m = values[0];
    if (m < 0 or m > MAX_OPERATIONS or length != @as(usize, @intCast(1 + 3 * m)) or length > 193) return -1;
    var queue = Queue{};
    var result: i64 = 0;
    for (0..@intCast(m)) |operation| {
        const offset = 1 + 3 * operation;
        const opcode = values[offset];
        const item_value = values[offset + 1];
        const key = values[offset + 2];
        if (opcode == 1) {
            if (item_value < 0 or item_value >= @as(i64, @intCast(MAX_ITEMS)) or key < 0 or key > MAX_KEY) return -1;
            const item: usize = @intCast(item_value);
            if (queue.active[item] or queue.node_count >= MAX_NODES) return -1;
            const node: usize = queue.node_count;
            queue.node_count += 1;
            queue.nodes[node] = .{ .key = key, .serial = queue.next_serial, .item_id = @intCast(item), .rank = 0, .first_child = -1, .next_sibling = -1, .parent = -2, .alive = true };
            queue.next_serial += 1;
            queue.active[item] = true;
            queue.insertSingleton(@intCast(node));
        } else if (opcode == 2 or opcode == 3) {
            if (item_value != 0 or key != 0) return -1;
            const root = queue.minimumRoot();
            if (root < 0) return -1;
            const root_index: usize = @intCast(root);
            result += (@as(i64, @intCast(operation)) + 1) * (queue.nodes[root_index].key + 1) + @as(i64, queue.nodes[root_index].item_id);
            if (opcode == 3) queue.deleteMin(root);
        } else return -1;
    }
    return result;
}
