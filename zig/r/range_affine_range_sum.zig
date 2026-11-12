const MODULUS: i64 = 998244353;
const MAX_LENGTH: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_TREE_NODES: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 387;

const AffineTree = struct {
    sum: [MAX_TREE_NODES]i64 = @splat(0),
    lazy_mul: [MAX_TREE_NODES]i64 = @splat(1),
    lazy_add: [MAX_TREE_NODES]i64 = @splat(0),

    fn apply(self: *AffineTree, node: usize, length: usize, a: i64, b: i64) void {
        self.sum[node] = @mod(a * self.sum[node] + b * @as(i64, @intCast(length)), MODULUS);
        self.lazy_mul[node] = @mod(a * self.lazy_mul[node], MODULUS);
        self.lazy_add[node] = @mod(a * self.lazy_add[node] + b, MODULUS);
    }

    fn push(self: *AffineTree, node: usize, left: usize, right: usize) void {
        if (right - left <= 1 or (self.lazy_mul[node] == 1 and self.lazy_add[node] == 0)) return;
        const middle = left + (right - left) / 2;
        const a = self.lazy_mul[node];
        const b = self.lazy_add[node];
        self.apply(node * 2, middle - left, a, b);
        self.apply(node * 2 + 1, right - middle, a, b);
        self.lazy_mul[node] = 1;
        self.lazy_add[node] = 0;
    }

    fn build(self: *AffineTree, values: []const i64, node: usize, left: usize, right: usize) void {
        if (right - left == 1) { self.sum[node] = values[left]; return; }
        const middle = left + (right - left) / 2;
        self.build(values, node * 2, left, middle);
        self.build(values, node * 2 + 1, middle, right);
        self.sum[node] = @mod(self.sum[node * 2] + self.sum[node * 2 + 1], MODULUS);
    }

    fn update(self: *AffineTree, ql: usize, qr: usize, node: usize, left: usize,
              right: usize, a: i64, b: i64) void {
        if (ql <= left and right <= qr) { self.apply(node, right - left, a, b); return; }
        if (qr <= left or right <= ql) return;
        self.push(node, left, right);
        const middle = left + (right - left) / 2;
        self.update(ql, qr, node * 2, left, middle, a, b);
        self.update(ql, qr, node * 2 + 1, middle, right, a, b);
        self.sum[node] = @mod(self.sum[node * 2] + self.sum[node * 2 + 1], MODULUS);
    }

    fn query(self: *AffineTree, ql: usize, qr: usize, node: usize,
             left: usize, right: usize) i64 {
        if (ql <= left and right <= qr) return self.sum[node];
        if (qr <= left or right <= ql) return 0;
        self.push(node, left, right);
        const middle = left + (right - left) / 2;
        return @mod(self.query(ql, qr, node * 2, left, middle) +
                    self.query(ql, qr, node * 2 + 1, middle, right), MODULUS);
    }
};

export fn range_affine_range_sum_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_LENGTH))) return -1;
    const n: usize = @intCast(input[0]);
    if (length < n + 2) return -1;
    var initial: [MAX_LENGTH]i64 = @splat(0);
    for (0..n) |i| {
        if (input[i + 1] < 0 or input[i + 1] >= MODULUS) return -1;
        initial[i] = input[i + 1];
    }
    if (input[n + 1] < 1 or input[n + 1] > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const operation_count: usize = @intCast(input[n + 1]);
    var tree = AffineTree{};
    tree.build(initial[0..n], 1, 0, n);
    var cursor = n + 2;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        if (cursor >= length) return -1;
        const opcode = input[cursor];
        cursor += 1;
        if (opcode == 0) {
            if (cursor + 4 > length) return -1;
            const left = input[cursor];
            const right = input[cursor + 1];
            const a = input[cursor + 2];
            const b = input[cursor + 3];
            cursor += 4;
            if (left < 0 or left >= right or right > @as(i64, @intCast(n)) or
                a < 1 or a >= MODULUS or b < 0 or b >= MODULUS) return -1;
            tree.update(@intCast(left), @intCast(right), 1, 0, n, a, b);
        } else if (opcode == 1) {
            if (cursor + 2 > length) return -1;
            const left = input[cursor];
            const right = input[cursor + 1];
            cursor += 2;
            if (left < 0 or left >= right or right > @as(i64, @intCast(n))) return -1;
            const result = tree.query(@intCast(left), @intCast(right), 1, 0, n);
            checksum += (@as(i64, @intCast(operation)) + 1) * (result + MODULUS);
        } else return -1;
    }
    return if (cursor == length) checksum else -1;
}
