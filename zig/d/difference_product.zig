// Independent difference-product Zig draft; see package README.
// Registered draft; compilation and arithmetic output remain unverified.
const std = @import("std");
const Allocator = std.mem.Allocator;
const prime: i64 = 998244353;

fn power(value: i64, exponent_value: i64) i64 {
    var base = value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) : (exponent >>= 1) {
        if ((exponent & 1) != 0) result = @rem(result * base, prime);
        base = @rem(base * base, prime);
    }
    return result;
}

fn transform(values: []i64, inverse: bool) void {
    const n = values.len;
    var reversed: usize = 0;
    for (1..n) |i| {
        var bit = n >> 1;
        while ((reversed & bit) != 0) { reversed ^= bit; bit >>= 1; }
        reversed ^= bit;
        if (i < reversed) std.mem.swap(i64, &values[i], &values[reversed]);
    }
    var width: usize = 2;
    while (width <= n) : (width *= 2) {
        var step = power(3, @divTrunc(prime - 1, @as(i64, @intCast(width))));
        if (inverse) step = power(step, prime - 2);
        var start: usize = 0;
        while (start < n) : (start += width) {
            var root: i64 = 1;
            for (0..width / 2) |j| {
                const a = values[start + j];
                const b = @rem(values[start + j + width / 2] * root, prime);
                values[start + j] = @rem(a + b, prime);
                values[start + j + width / 2] = @rem(a - b + prime, prime);
                root = @rem(root * step, prime);
            }
        }
    }
    if (inverse) {
        const scale = power(@intCast(n), prime - 2);
        for (values) |*value| value.* = @rem(value.* * scale, prime);
    }
}

// Returned slices are caller-owned. Allocation errors propagate to the ABI.
fn multiply(allocator: Allocator, a: []const i64, b: []const i64) ![]i64 {
    if (a.len == 0 or b.len == 0) return try allocator.alloc(i64, 0);
    const needed = a.len + b.len - 1;
    const result = try allocator.alloc(i64, needed);
    errdefer allocator.free(result);
    @memset(result, 0);
    if (a.len <= 32 or b.len <= 32) {
        for (a, 0..) |x, i| {
            for (b, 0..) |y, j| result[i + j] = @rem(result[i + j] + x * y, prime);
        }
        return result;
    }
    var size: usize = 1;
    while (size < needed) size *= 2;
    const left = try allocator.alloc(i64, size);
    defer allocator.free(left);
    const right = try allocator.alloc(i64, size);
    defer allocator.free(right);
    @memset(left, 0);
    @memset(right, 0);
    @memcpy(left[0..a.len], a);
    @memcpy(right[0..b.len], b);
    transform(left, false);
    transform(right, false);
    for (0..size) |i| left[i] = @rem(left[i] * right[i], prime);
    transform(left, true);
    @memcpy(result, left[0..needed]);
    return result;
}

// Newton doubling, with caller ownership of the returned coefficient slice.
fn inverseSeries(allocator: Allocator, poly: []const i64, count: usize) ![]i64 {
    var inverse = try allocator.alloc(i64, 1);
    errdefer allocator.free(inverse);
    inverse[0] = power(poly[0], prime - 2);
    while (inverse.len < count) {
        const n = @min(2 * inverse.len, count);
        const prefix = poly[0..@min(poly.len, n)];
        const product = try multiply(allocator, prefix, inverse);
        defer allocator.free(product);
        const correction = try allocator.alloc(i64, n);
        defer allocator.free(correction);
        for (0..n) |i| {
            const value: i64 = if (i < product.len) product[i] else 0;
            correction[i] = @rem(prime - value, prime);
        }
        correction[0] = @rem(correction[0] + 2, prime);
        const updated = try multiply(allocator, inverse, correction);
        defer allocator.free(updated);
        const next = try allocator.alloc(i64, n);
        @memcpy(next, updated[0..n]);
        allocator.free(inverse);
        inverse = next;
    }
    return inverse;
}

// Remainder modulo a nonzero monic polynomial, using a reversed quotient.
fn remainder(allocator: Allocator, dividend: []const i64, divisor: []const i64) ![]i64 {
    if (dividend.len < divisor.len) return try allocator.dupe(i64, dividend);
    if (divisor.len == 1) return try allocator.alloc(i64, 0);
    const count = dividend.len - divisor.len + 1;
    const high = try allocator.alloc(i64, count);
    defer allocator.free(high);
    const reversed = try allocator.alloc(i64, divisor.len);
    defer allocator.free(reversed);
    for (0..count) |i| high[i] = dividend[dividend.len - 1 - i];
    for (0..divisor.len) |i| reversed[i] = divisor[divisor.len - 1 - i];
    const inverse = try inverseSeries(allocator, reversed, count);
    defer allocator.free(inverse);
    const high_quotient = try multiply(allocator, high, inverse);
    defer allocator.free(high_quotient);
    const quotient = try allocator.alloc(i64, count);
    defer allocator.free(quotient);
    for (0..count) |i| quotient[i] = high_quotient[count - 1 - i];
    const removed = try multiply(allocator, quotient, divisor);
    defer allocator.free(removed);
    const provisional = try allocator.alloc(i64, divisor.len - 1);
    defer allocator.free(provisional);
    for (0..provisional.len) |i|
        provisional[i] = @rem(dividend[i] - removed[i] + prime, prime);
    var used = provisional.len;
    while (used > 0 and provisional[used - 1] == 0) used -= 1;
    return try allocator.dupe(i64, provisional[0..used]);
}

const PointTree = struct {
    allocator: Allocator,
    size: usize,
    count: usize,
    nodes: []?[]i64,

    fn init(allocator: Allocator, points: []const i64) Allocator.Error!PointTree {
        var size: usize = 1;
        while (size < points.len) size *= 2;
        const nodes = try allocator.alloc(?[]i64, 2 * size);
        @memset(nodes, null);
        var tree = PointTree{ .allocator = allocator, .size = size, .count = points.len, .nodes = nodes };
        errdefer tree.deinit();
        for (0..size) |i| {
            const leaf = try allocator.alloc(i64, if (i < points.len) 2 else 1);
            tree.nodes[size + i] = leaf;
            if (i < points.len) {
                leaf[0] = @rem(prime - points[i], prime);
                leaf[1] = 1;
            } else leaf[0] = 1;
        }
        var node = size;
        while (node > 1) {
            node -= 1;
            tree.nodes[node] = try multiply(allocator, tree.nodes[2 * node].?, tree.nodes[2 * node + 1].?);
        }
        return tree;
    }

    fn deinit(self: *PointTree) void {
        for (self.nodes) |maybe| if (maybe) |coefficients| self.allocator.free(coefficients);
        self.allocator.free(self.nodes);
    }

    fn visit(self: *const PointTree, node: usize, value: []const i64,
             output: []i64) Allocator.Error!void {
        if (value.len == 0) return;
        if (node >= self.size) {
            const index = node - self.size;
            if (index < self.count) output[index] = value[0];
            return;
        }
        const left = try remainder(self.allocator, value, self.nodes[2 * node].?);
        defer self.allocator.free(left);
        const right = try remainder(self.allocator, value, self.nodes[2 * node + 1].?);
        defer self.allocator.free(right);
        try self.visit(2 * node, left, output);
        try self.visit(2 * node + 1, right, output);
    }
};

fn orderedProduct(allocator: Allocator, points: []const i64) Allocator.Error!i64 {
    if (points.len <= 32) {
        var product: i64 = 1;
        for (0..points.len) |i| {
            for (i + 1..points.len) |j|
                product = @rem(product * @rem(points[i] - points[j] + prime, prime), prime);
        }
        return product;
    }
    const middle = points.len / 2;
    const left = points[0..middle];
    const right = points[middle..];
    var product = @rem((try orderedProduct(allocator, left)) * (try orderedProduct(allocator, right)), prime);
    if (product == 0) return 0;
    var left_tree = try PointTree.init(allocator, left);
    defer left_tree.deinit();
    var right_tree = try PointTree.init(allocator, right);
    defer right_tree.deinit();
    const root = try remainder(allocator, left_tree.nodes[1].?, right_tree.nodes[1].?);
    defer allocator.free(root);
    const evaluations = try allocator.alloc(i64, right.len);
    defer allocator.free(evaluations);
    @memset(evaluations, 0);
    try right_tree.visit(1, root, evaluations);
    for (evaluations) |value| product = @rem(product * value, prime);
    if ((left.len & 1) != 0 and (right.len & 1) != 0 and product != 0) product = prime - product;
    return product;
}

export fn difference_product(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or input[0] < 0 or input[0] > 65536) return -1;
    const count: usize = @intCast(input[0]);
    if (length != count + 1) return -1;
    for (0..count) |i| if (input[i + 1] < 0 or input[i + 1] >= prime) return -1;
    return orderedProduct(std.heap.page_allocator, input[1 .. count + 1]) catch -1;
}
