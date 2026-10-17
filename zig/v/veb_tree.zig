const MAX_COUNT: usize = 256;
const MAX_INPUT_VALUES: usize = 771;
const MAX_OUTPUT_BYTES: usize = 1024;
const MAX_TREE_NODES: usize = 358;
const MAX_CLUSTERS: usize = 16;

const VebNode = struct {
    universe: u16 = 0,
    low_bits: u8 = 0,
    cluster_count: u8 = 0,
    minimum: i32 = -1,
    maximum: i32 = 0,
    summary: i32 = -1,
    clusters: [MAX_CLUSTERS]i32 = [_]i32{0} ** MAX_CLUSTERS,
};

fn initialize(nodes: *[MAX_TREE_NODES]VebNode, next: *usize, universe: u32) i32 {
    const id: i32 = @intCast(next.*);
    next.* += 1;
    nodes.*[@intCast(id)] = .{ .universe = @intCast(universe) };
    if (universe > 2) {
        const exponent: u5 = @intCast(31 - @clz(universe));
        const low_bits: u5 = exponent / 2;
        const low_size = @as(u32, 1) << low_bits;
        const cluster_count = universe / low_size;
        nodes.*[@intCast(id)].low_bits = @intCast(low_bits);
        nodes.*[@intCast(id)].cluster_count = @intCast(cluster_count);
        const summary = initialize(nodes, next, cluster_count);
        nodes.*[@intCast(id)].summary = summary;
        for (0..cluster_count) |index| {
            const child = initialize(nodes, next, low_size);
            nodes.*[@intCast(id)].clusters[@intCast(index)] = child;
        }
    }
    return id;
}

fn contains(nodes: *const [MAX_TREE_NODES]VebNode, id: i32, value: u32) bool {
    const node = nodes.*[@intCast(id)];
    if (node.minimum < 0) return false;
    if (@as(u32, @intCast(node.minimum)) == value or @as(u32, @intCast(node.maximum)) == value) return true;
    if (node.universe == 2) return false;
    const low_size: u32 = @as(u32, 1) << node.low_bits;
    const high = value >> node.low_bits;
    const low = value & (low_size - 1);
    return contains(nodes, node.clusters[@intCast(high)], low);
}

fn insert(nodes: *[MAX_TREE_NODES]VebNode, id: i32, initial_value: u32) void {
    if (contains(nodes, id, initial_value)) return;
    if (nodes.*[@intCast(id)].minimum < 0) {
        nodes.*[@intCast(id)].minimum = @intCast(initial_value);
        nodes.*[@intCast(id)].maximum = @intCast(initial_value);
        return;
    }
    var value = initial_value;
    if (value < @as(u32, @intCast(nodes.*[@intCast(id)].minimum))) {
        const old_minimum: u32 = @intCast(nodes.*[@intCast(id)].minimum);
        nodes.*[@intCast(id)].minimum = @intCast(value);
        value = old_minimum;
    }
    if (nodes.*[@intCast(id)].universe > 2) {
        const low_bits = nodes.*[@intCast(id)].low_bits;
        const low_size: u32 = @as(u32, 1) << low_bits;
        const high = value >> low_bits;
        const low = value & (low_size - 1);
        const cluster = nodes.*[@intCast(id)].clusters[@intCast(high)];
        if (nodes.*[@intCast(cluster)].minimum < 0) {
            const summary = nodes.*[@intCast(id)].summary;
            insert(nodes, summary, high);
            nodes.*[@intCast(cluster)].minimum = @intCast(low);
            nodes.*[@intCast(cluster)].maximum = @intCast(low);
        } else {
            insert(nodes, cluster, low);
        }
    }
    if (value > @as(u32, @intCast(nodes.*[@intCast(id)].maximum))) nodes.*[@intCast(id)].maximum = @intCast(value);
}

fn successor(nodes: *const [MAX_TREE_NODES]VebNode, id: i32, value: u32) i32 {
    const node = nodes.*[@intCast(id)];
    if (node.minimum < 0) return -1;
    if (value < @as(u32, @intCast(node.minimum))) return node.minimum;
    if (node.universe == 2) return if (value == 0 and node.maximum == 1) 1 else -1;
    const low_size: u32 = @as(u32, 1) << node.low_bits;
    const high = value >> node.low_bits;
    const low = value & (low_size - 1);
    const cluster = node.clusters[@intCast(high)];
    if (nodes.*[@intCast(cluster)].minimum >= 0 and low < @as(u32, @intCast(nodes.*[@intCast(cluster)].maximum))) {
        const next_low = successor(nodes, cluster, low);
        if (next_low < 0) return -1;
        return @as(i32, @intCast(high * low_size)) + next_low;
    }
    const next_cluster = successor(nodes, node.summary, high);
    if (next_cluster < 0) return -1;
    const next_minimum = nodes.*[@intCast(node.clusters[@intCast(next_cluster)])].minimum;
    if (next_minimum < 0) return -1;
    return next_cluster * @as(i32, @intCast(low_size)) + next_minimum;
}

fn predecessor(nodes: *const [MAX_TREE_NODES]VebNode, id: i32, value: u32) i32 {
    const node = nodes.*[@intCast(id)];
    if (node.minimum < 0 or value <= @as(u32, @intCast(node.minimum))) return -1;
    if (value > @as(u32, @intCast(node.maximum))) return node.maximum;
    if (node.universe == 2) return if (value == 1 and node.minimum == 0) 0 else -1;
    const low_size: u32 = @as(u32, 1) << node.low_bits;
    const high = value >> node.low_bits;
    const low = value & (low_size - 1);
    const cluster = node.clusters[@intCast(high)];
    if (nodes.*[@intCast(cluster)].minimum >= 0 and low > @as(u32, @intCast(nodes.*[@intCast(cluster)].minimum))) {
        const previous_low = predecessor(nodes, cluster, low);
        if (previous_low >= 0) return @as(i32, @intCast(high * low_size)) + previous_low;
    }
    const previous_cluster = predecessor(nodes, node.summary, high);
    if (previous_cluster < 0) return node.minimum;
    const previous_maximum = nodes.*[@intCast(node.clusters[@intCast(previous_cluster)])].maximum;
    if (previous_maximum < 0) return -1;
    return previous_cluster * @as(i32, @intCast(low_size)) + previous_maximum;
}

export fn veb_tree(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_VALUES + 1) return -1;
    const source = input.?;
    if (source[0] < 2 or source[0] > 256 or source[1] < 0 or source[1] > @as(i64, MAX_COUNT) or source[2] < 0 or source[2] > @as(i64, MAX_COUNT)) return -1;
    const requested: u32 = @intCast(source[0]);
    const insert_count: usize = @intCast(source[1]);
    const query_count: usize = @intCast(source[2]);
    if (length != 3 + insert_count + 2 * query_count) return -1;
    for (0..insert_count) |index| {
        if (source[3 + index] < 0 or source[3 + index] >= requested) return -1;
    }
    for (0..query_count) |index| {
        const opcode = source[3 + insert_count + 2 * index];
        const key = source[4 + insert_count + 2 * index];
        if (opcode < 0 or opcode > 4 or key < 0 or key >= requested) return -1;
    }
    const needed = query_count * 4;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == null or capacity < needed) return -2;
    var rounded: u32 = 1;
    while (rounded < requested) : (rounded <<= 1) {}
    var nodes = [_]VebNode{.{}} ** MAX_TREE_NODES;
    var next: usize = 0;
    const root = initialize(&nodes, &next, rounded);
    for (0..insert_count) |index| insert(&nodes, root, @intCast(source[3 + index]));
    var result: [MAX_OUTPUT_BYTES]u8 = undefined;
    for (0..query_count) |index| {
        const opcode = source[3 + insert_count + 2 * index];
        const key: u32 = @intCast(source[4 + insert_count + 2 * index]);
        const value: i32 = if (opcode == 0)
            @intFromBool(contains(&nodes, root, key))
        else if (opcode == 1)
            successor(&nodes, root, key)
        else if (opcode == 2)
            predecessor(&nodes, root, key)
        else if (opcode == 3)
            nodes[@intCast(root)].minimum
        else if (nodes[@intCast(root)].minimum < 0)
            0
        else
            nodes[@intCast(root)].maximum;
        const bits: u32 = @bitCast(value);
        result[4 * index] = @truncate(bits);
        result[4 * index + 1] = @truncate(bits >> 8);
        result[4 * index + 2] = @truncate(bits >> 16);
        result[4 * index + 3] = @truncate(bits >> 24);
    }
    const dest = output.?;
    for (0..needed) |index| dest[index] = result[index];
    return @intCast(needed);
}
