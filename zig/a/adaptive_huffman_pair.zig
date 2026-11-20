const alphabet: usize = 16;
const max_nodes: usize = 31;
const max_input: usize = 66;
const max_packed: usize = 152;
const nyt_kind: i32 = 0;
const leaf_kind: i32 = 1;
const internal_kind: i32 = 2;

const Node = struct { parent: i32 = -1, left: i32 = -1, right: i32 = -1, symbol: i32 = -1, kind: i32 = nyt_kind, weight: i64 = 0 };
const Ordered = struct { id: usize = 0, depth: usize = 0, path: usize = 0 };
const Tree = struct {
    nodes: [max_nodes]Node = [_]Node{.{}} ** max_nodes,
    count: usize = 1,
    root: usize = 0,
    nyt: i32 = 0,
    leaf: [alphabet]i32 = [_]i32{-1} ** alphabet,
    order: [max_nodes]usize = [_]usize{0} ** max_nodes,
    order_count: usize = 1,
    bits: [max_packed]u8 = [_]u8{0} ** max_packed,
    bit_count: usize = 0,

    fn putBit(self: *Tree, value: usize) void {
        if (value != 0) self.bits[self.bit_count / 8] |= @as(u8, 1) << @intCast(7 - self.bit_count % 8);
        self.bit_count += 1;
    }
    fn putValue(self: *Tree, value: usize, width: usize) void {
        var shift = width;
        while (shift > 0) { shift -= 1; self.putBit((value >> @intCast(shift)) & 1); }
    }
    fn encodePath(self: *Tree, initial: usize) void {
        var reverse: [max_nodes]usize = [_]usize{0} ** max_nodes;
        var depth: usize = 0; var node = initial;
        while (node != self.root) {
            const parent: usize = @intCast(self.nodes[node].parent);
            reverse[depth] = if (self.nodes[parent].right == node) 1 else 0;
            depth += 1; node = parent;
        }
        while (depth > 0) { depth -= 1; self.putBit(reverse[depth]); }
    }
    fn ancestor(self: *const Tree, ancestor_id: usize, node: usize) bool {
        var at = self.nodes[node].parent;
        while (at >= 0) { if (@as(usize, @intCast(at)) == ancestor_id) return true; at = self.nodes[@intCast(at)].parent; }
        return false;
    }
    fn replaceChild(self: *Tree, parent: usize, old: usize, new: usize) void {
        if (self.nodes[parent].left == @as(i32, @intCast(old))) self.nodes[parent].left = @intCast(new)
        else if (self.nodes[parent].right == @as(i32, @intCast(old))) self.nodes[parent].right = @intCast(new);
    }
    fn swap(self: *Tree, a: usize, b: usize, update_order: bool) void {
        if (a == b or self.nodes[a].parent == @as(i32, @intCast(b)) or self.nodes[b].parent == @as(i32, @intCast(a)) or self.ancestor(a, b) or self.ancestor(b, a)) return;
        const pa = self.nodes[a].parent; const pb = self.nodes[b].parent;
        if (pa == pb) {
            if (pa >= 0) { const p: usize = @intCast(pa); const temp = self.nodes[p].left; self.nodes[p].left = self.nodes[p].right; self.nodes[p].right = temp; }
        } else {
            if (pa >= 0) self.replaceChild(@intCast(pa), a, b);
            if (pb >= 0) self.replaceChild(@intCast(pb), b, a);
            self.nodes[a].parent = pb; self.nodes[b].parent = pa;
        }
        if (self.root == a) self.root = b else if (self.root == b) self.root = a;
        if (update_order) {
            var ra: ?usize = null; var rb: ?usize = null;
            for (0..self.order_count) |i| { if (self.order[i] == a) ra = i; if (self.order[i] == b) rb = i; }
            if (ra) |x| { if (rb) |y| { self.order[x] = b; self.order[y] = a; } }
        }
    }
    fn addNode(self: *Tree, parent: usize, kind: i32, symbol: i32) usize {
        const id = self.count; self.count += 1;
        self.nodes[id] = .{ .parent = @intCast(parent), .left = -1, .right = -1, .symbol = symbol, .kind = kind, .weight = 0 };
        return id;
    }
    fn split(self: *Tree, symbol: usize, remaining: bool, fgk: bool) usize {
        const old: usize = @intCast(self.nyt);
        if (!remaining) { self.nodes[old].kind = leaf_kind; self.nodes[old].symbol = @intCast(symbol); self.leaf[symbol] = @intCast(old); self.nyt = -1; return old; }
        const left = self.addNode(old, nyt_kind, -1); const right = self.addNode(old, leaf_kind, @intCast(symbol));
        self.nodes[old].kind = internal_kind; self.nodes[old].left = @intCast(left); self.nodes[old].right = @intCast(right);
        self.leaf[symbol] = @intCast(right); self.nyt = @intCast(left);
        if (fgk) {
            var pos: usize = 0; while (self.order[pos] != old) : (pos += 1) {}
            var i = self.order_count + 1; while (i > pos + 2) { self.order[i] = self.order[i - 2]; i -= 1; }
            self.order[pos] = left; self.order[pos + 1] = right; self.order[pos + 2] = old; self.order_count += 2;
        }
        return right;
    }
    fn fgkLeader(self: *const Tree, node: usize, leaves_only: bool) usize {
        var i = self.order_count;
        while (i > 0) {
            i -= 1; const candidate = self.order[i];
            if (@as(i32, @intCast(candidate)) == self.nodes[node].parent or self.nodes[candidate].weight != self.nodes[node].weight or (leaves_only and self.nodes[candidate].kind == internal_kind) or self.ancestor(candidate, node) or self.ancestor(node, candidate)) continue;
            return candidate;
        }
        return node;
    }
    fn updateFgk(self: *Tree, initial: usize) void {
        var node = initial; const parent = self.nodes[node].parent;
        if (self.nyt >= 0 and parent >= 0 and self.nodes[@intCast(self.nyt)].parent == parent) { self.swap(node, self.fgkLeader(node, true), true); self.nodes[node].weight += 1; node = @intCast(self.nodes[node].parent); }
        while (node != self.root) { self.swap(node, self.fgkLeader(node, false), true); self.nodes[node].weight += 1; node = @intCast(self.nodes[node].parent); }
        self.nodes[self.root].weight += 1;
    }
    fn implicitOrder(self: *const Tree, out: *[max_nodes]Ordered) usize {
        for (0..self.count) |id| {
            var reverse: [max_nodes]usize = [_]usize{0} ** max_nodes; var depth: usize = 0; var at = id;
            while (at != self.root) { const p: usize = @intCast(self.nodes[at].parent); reverse[depth] = if (self.nodes[p].right == at) 1 else 0; depth += 1; at = p; }
            var path: usize = 0; var j = depth; while (j > 0) { j -= 1; path = path * 2 + reverse[j]; }
            out[id] = .{ .id = id, .depth = depth, .path = path };
        }
        for (1..self.count) |i| {
            const value = out[i]; var j = i;
            while (j > 0 and (out[j - 1].depth < value.depth or (out[j - 1].depth == value.depth and out[j - 1].path > value.path))) { out[j] = out[j - 1]; j -= 1; }
            out[j] = value;
        }
        return self.count;
    }
    fn vitterLeader(self: *const Tree, node: usize, order: *[max_nodes]Ordered) usize {
        const count = self.implicitOrder(order); var i = count;
        while (i > 0) { i -= 1; const id = order[i].id; if (self.nodes[id].weight == self.nodes[node].weight and self.nodes[id].kind == self.nodes[node].kind) return id; }
        return node;
    }
    fn slideIncrement(self: *Tree, node: usize, order: *[max_nodes]Ordered) usize {
        const old_parent = self.nodes[node].parent;
        const target_kind = if (self.nodes[node].kind == leaf_kind) internal_kind else leaf_kind;
        const target_weight = self.nodes[node].weight + @as(i64, if (self.nodes[node].kind == leaf_kind) 0 else 1);
        const count = self.implicitOrder(order); var block: [max_nodes]usize = [_]usize{0} ** max_nodes; var used: usize = 0;
        for (0..count) |i| { const id = order[i].id; if (self.nodes[id].kind == target_kind and self.nodes[id].weight == target_weight) { block[used] = id; used += 1; } }
        for (0..used) |i| { if (block[i] != node) self.swap(node, block[i], false); }
        self.nodes[node].weight += 1;
        return if (self.nodes[node].kind == leaf_kind) @intCast(self.nodes[node].parent) else @intCast(old_parent);
    }
    fn updateVitter(self: *Tree, initial: usize, just_split: bool) void {
        var order: [max_nodes]Ordered = [_]Ordered{.{}} ** max_nodes; var node = initial; var leaf_to_increment: ?usize = null;
        if (just_split) { leaf_to_increment = node; node = @intCast(self.nodes[node].parent); }
        else { self.swap(node, self.vitterLeader(node, &order), false); const parent = self.nodes[node].parent; if (self.nyt >= 0 and parent >= 0 and self.nodes[@intCast(self.nyt)].parent == parent) { leaf_to_increment = node; node = @intCast(parent); } }
        while (node != self.root) node = self.slideIncrement(node, &order);
        if (leaf_to_increment) |leaf_id| { _ = self.slideIncrement(leaf_id, &order); }
        self.nodes[self.root].weight += 1;
    }
};

fn encode(values: []const i64, use_vitter: bool, bits: *[max_packed]u8, bit_count: *usize) i64 {
    if (values.len < 1 or values.len > max_input) return -1;
    if (values[0] < 0 or values[0] > 64 or values.len != 1 + @as(usize, @intCast(values[0]))) return -1;
    for (values[1..]) |symbol| { if (symbol < 0 or symbol >= 16) return -1; }
    var tree: Tree = .{}; var seen: usize = 0;
    for (values[1..]) |symbol_value| {
        const symbol: usize = @intCast(symbol_value); const is_new = tree.leaf[symbol] < 0;
        var current: usize = if (is_new) @intCast(tree.nyt) else @intCast(tree.leaf[symbol]);
        tree.encodePath(current);
        if (is_new) { tree.putValue(symbol, 4); seen += 1; const split = seen < alphabet; current = tree.split(symbol, split, !use_vitter); if (use_vitter) tree.updateVitter(current, split) else tree.updateFgk(current); }
        else if (use_vitter) tree.updateVitter(current, false) else tree.updateFgk(current);
    }
    bits.* = tree.bits; bit_count.* = tree.bit_count; return 0;
}
fn call(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize, use_vitter: bool) i64 {
    if (input == null or length < 1 or length > max_input) return -1;
    var bits: [max_packed]u8 = [_]u8{0} ** max_packed; var bit_count: usize = 0;
    const status = encode(input[0..length], use_vitter, &bits, &bit_count); if (status < 0) return status;
    const packed = (bit_count + 7) / 8; const required = 8 + packed;
    if (output == null or capacity < required) return -2;
    const count64: u64 = @intCast(bit_count);
    for (0..8) |i| output[i] = @truncate(count64 >> @intCast(i * 8));
    for (0..packed) |i| output[8 + i] = bits[i];
    return @intCast(required);
}
export fn fgk_adaptive_huffman(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 { return call(input, length, output, capacity, false); }
export fn vitter_adaptive_huffman(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 { return call(input, length, output, capacity, true); }
