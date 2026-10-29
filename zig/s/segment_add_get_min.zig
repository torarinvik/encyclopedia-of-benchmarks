const std = @import("std");

const max_initial_segments: i64 = 16;
const max_operations: i64 = 32;
const domain_low: i64 = -32;
const domain_high: i64 = 31;
const domain_right: i64 = 32;
const coefficient_limit: i64 = 1_000;
const infinity_value: i64 = 1_000_000_000_000;
const checksum_offset: i64 = 33_001;
const tree_capacity: usize = 4 * 64 + 8;
const max_input_length: usize = 2 + 4 * 16 + 5 * 32;

const Node = struct {
    slope: i64 = 0,
    intercept: i64 = 0,
    occupied: bool = false,
};

const SegmentLiChao = struct {
    nodes: [tree_capacity]Node = [_]Node{.{}} ** tree_capacity,

    fn evaluate(slope: i64, intercept: i64, x: i64) i64 {
        return slope * x + intercept;
    }

    fn addLine(self: *SegmentLiChao, node: usize, low: i64, high: i64, new_slope: i64, new_intercept: i64) void {
        if (!self.nodes[node].occupied) {
            self.nodes[node] = .{ .slope = new_slope, .intercept = new_intercept, .occupied = true };
            return;
        }
        var slope = new_slope;
        var intercept = new_intercept;
        const middle = low + @divTrunc(high - low, 2);
        if (evaluate(slope, intercept, middle) < evaluate(self.nodes[node].slope, self.nodes[node].intercept, middle)) {
            std.mem.swap(i64, &slope, &self.nodes[node].slope);
            std.mem.swap(i64, &intercept, &self.nodes[node].intercept);
        }
        if (low == high) return;
        if (evaluate(slope, intercept, low) < evaluate(self.nodes[node].slope, self.nodes[node].intercept, low)) {
            self.addLine(2 * node, low, middle, slope, intercept);
        } else if (evaluate(slope, intercept, high) < evaluate(self.nodes[node].slope, self.nodes[node].intercept, high)) {
            self.addLine(2 * node + 1, middle + 1, high, slope, intercept);
        }
    }

    fn addSegment(self: *SegmentLiChao, node: usize, low: i64, high: i64,
                  query_low: i64, query_high: i64, slope: i64, intercept: i64) void {
        if (query_high <= low or high < query_low) return;
        if (query_low <= low and high < query_high) {
            self.addLine(node, low, high, slope, intercept);
            return;
        }
        const middle = low + @divTrunc(high - low, 2);
        self.addSegment(2 * node, low, middle, query_low, query_high, slope, intercept);
        self.addSegment(2 * node + 1, middle + 1, high, query_low, query_high, slope, intercept);
    }

    fn minimumAt(self: *const SegmentLiChao, node: usize, low: i64, high: i64, x: i64) i64 {
        const current = self.nodes[node];
        var best = if (current.occupied) evaluate(current.slope, current.intercept, x) else infinity_value;
        if (low == high) return best;
        const middle = low + @divTrunc(high - low, 2);
        const go_left = x <= middle;
        const nested = self.minimumAt(
            if (go_left) 2 * node else 2 * node + 1,
            if (go_left) low else middle + 1,
            if (go_left) middle else high,
            x,
        );
        best = @min(best, nested);
        return best;
    }
};

fn validSegment(left: i64, right: i64, slope: i64, intercept: i64) bool {
    return left >= domain_low and left < right and right <= domain_right and
        slope >= -coefficient_limit and slope <= coefficient_limit and
        intercept >= -coefficient_limit and intercept <= coefficient_limit;
}

export fn segment_add_get_min(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > max_input_length) return -1;
    const packed = values.?;
    const initial_value = packed[0];
    const operation_value = packed[1];
    if (initial_value < 0 or initial_value > max_initial_segments or
        operation_value < 0 or operation_value > max_operations) return -1;
    const initial_count: usize = @intCast(initial_value);
    const operation_count: usize = @intCast(operation_value);

    var tree = SegmentLiChao{};
    var position: usize = 2;
    for (0..initial_count) |_| {
        if (length - position < 4) return -1;
        const left = packed[position];
        const right = packed[position + 1];
        const slope = packed[position + 2];
        const intercept = packed[position + 3];
        if (!validSegment(left, right, slope, intercept)) return -1;
        tree.addSegment(1, domain_low, domain_high, left, right, slope, intercept);
        position += 4;
    }

    var checksum: i64 = 0;
    var query_number: i64 = 0;
    for (0..operation_count) |_| {
        if (position >= length) return -1;
        const opcode = packed[position];
        position += 1;
        if (opcode == 0) {
            if (length - position < 4) return -1;
            const left = packed[position];
            const right = packed[position + 1];
            const slope = packed[position + 2];
            const intercept = packed[position + 3];
            if (!validSegment(left, right, slope, intercept)) return -1;
            tree.addSegment(1, domain_low, domain_high, left, right, slope, intercept);
            position += 4;
        } else if (opcode == 1) {
            if (position >= length) return -1;
            const x = packed[position];
            position += 1;
            if (x < domain_low or x > domain_high) return -1;
            const answer = tree.minimumAt(1, domain_low, domain_high, x);
            query_number += 1;
            checksum += query_number * (answer + checksum_offset);
        } else {
            return -1;
        }
    }
    if (position != length) return -1;
    return checksum;
}
