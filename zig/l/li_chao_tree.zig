const std = @import("std");

const max_operations: usize = 512;
const max_nodes: usize = max_operations * 24 + 1;
const domain_low: i64 = -1_000_000;
const domain_high: i64 = 1_000_000;
const coefficient_limit: i64 = 1_000;
const checksum_offset: i64 = 1_000_001_001;

const Node = struct {
    slope: i64 = 0,
    intercept: i64 = 0,
    left: i32 = -1,
    right: i32 = -1,
    occupied: bool = false,
};

const Tree = struct {
    nodes: [max_nodes]Node = [_]Node{.{}} ** max_nodes,
    used: usize = 0,
    root: i32 = -1,

    fn evaluate(slope: i64, intercept: i64, x: i64) i64 {
        return slope * x + intercept;
    }

    fn allocate(self: *Tree) ?i32 {
        if (self.used == max_nodes) return null;
        const id: i32 = @intCast(self.used);
        self.used += 1;
        return id;
    }

    fn insertAt(self: *Tree, id: i32, low: i64, high: i64, new_slope: i64, new_intercept: i64) bool {
        const index: usize = @intCast(id);
        if (!self.nodes[index].occupied) {
            self.nodes[index].slope = new_slope;
            self.nodes[index].intercept = new_intercept;
            self.nodes[index].occupied = true;
            return true;
        }

        var slope = new_slope;
        var intercept = new_intercept;
        const middle = low + @divTrunc(high - low, 2);
        if (evaluate(slope, intercept, middle) < evaluate(self.nodes[index].slope, self.nodes[index].intercept, middle)) {
            std.mem.swap(i64, &slope, &self.nodes[index].slope);
            std.mem.swap(i64, &intercept, &self.nodes[index].intercept);
        }
        if (low == high) return true;

        const left_side = evaluate(slope, intercept, low) < evaluate(self.nodes[index].slope, self.nodes[index].intercept, low);
        const right_side = evaluate(slope, intercept, high) < evaluate(self.nodes[index].slope, self.nodes[index].intercept, high);
        if (!left_side and !right_side) return true;
        const go_left = left_side;
        const next_low = if (go_left) low else middle + 1;
        const next_high = if (go_left) middle else high;
        var child = if (go_left) self.nodes[index].left else self.nodes[index].right;
        if (child < 0) {
            child = self.allocate() orelse return false;
            if (go_left) self.nodes[index].left = child else self.nodes[index].right = child;
        }
        return self.insertAt(child, next_low, next_high, slope, intercept);
    }

    fn add(self: *Tree, slope: i64, intercept: i64) bool {
        if (self.root < 0) self.root = self.allocate() orelse return false;
        return self.insertAt(self.root, domain_low, domain_high, slope, intercept);
    }

    fn minimumAt(self: *const Tree, id: i32, low: i64, high: i64, x: i64) i64 {
        const node = self.nodes[@intCast(id)];
        var best = evaluate(node.slope, node.intercept, x);
        if (low == high) return best;
        const middle = low + @divTrunc(high - low, 2);
        const go_left = x <= middle;
        const child = if (go_left) node.left else node.right;
        if (child >= 0) {
            const nested = self.minimumAt(child,
                if (go_left) low else middle + 1,
                if (go_left) middle else high, x);
            best = @min(best, nested);
        }
        return best;
    }
};

export fn li_chao_tree(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > 1 + 3 * max_operations) return -1;
    const packed = values.?;
    if (packed[0] < 0 or packed[0] > @as(i64, @intCast(max_operations))) return -1;
    const operation_count: usize = @intCast(packed[0]);
    if (length != 1 + 3 * operation_count) return -1;

    var tree = Tree{};
    var inserted: usize = 0;
    var query_number: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const offset = 1 + 3 * operation;
        const opcode = packed[offset];
        const first = packed[offset + 1];
        const second = packed[offset + 2];
        if (opcode == 0) {
            if (first < -coefficient_limit or first > coefficient_limit or second < -coefficient_limit or second > coefficient_limit) return -1;
            if (!tree.add(first, second)) return -1;
            inserted += 1;
        } else if (opcode == 1) {
            if (first < domain_low or first > domain_high or second != 0 or inserted == 0) return -1;
            const answer = tree.minimumAt(tree.root, domain_low, domain_high, first);
            query_number += 1;
            checksum += @as(i64, @intCast(query_number)) * (answer + checksum_offset);
        } else {
            return -1;
        }
    }
    return checksum;
}
