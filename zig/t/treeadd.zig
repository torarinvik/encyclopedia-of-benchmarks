const MAX_LEVEL: i64 = 12;
const MAX_NODES: usize = (1 << 12) - 1;
const ADDITION_PASSES = 100;

const Node = struct {
    value: i32,
    left: i32,
    right: i32,
};

fn allocateTree(nodes: []Node, used: *usize, level: i32, lo: i32, proc_count: i32) i32 {
    if (level == 0 or used.* >= MAX_NODES) return -1;
    const index: i32 = @intCast(used.*);
    used.* += 1;
    nodes[@intCast(index)].value = 1;
    const left = allocateTree(nodes, used, level - 1, lo + @divTrunc(proc_count, 2),
        @divTrunc(proc_count, 2));
    const right = allocateTree(nodes, used, level - 1, lo, @divTrunc(proc_count, 2));
    nodes[@intCast(index)].left = left;
    nodes[@intCast(index)].right = right;
    return index;
}

fn treeAdd(nodes: []const Node, index: i32) i64 {
    if (index < 0) return 0;
    const node = nodes[@intCast(index)];
    return @as(i64, node.value) + treeAdd(nodes, node.left) + treeAdd(nodes, node.right);
}

export fn treeadd(level: i64) i64 {
    if (level < 0 or level > MAX_LEVEL) return -1;
    var nodes: [MAX_NODES]Node = undefined;
    var used: usize = 0;
    const root = allocateTree(nodes[0..], &used, @intCast(level), 0, 4);
    var result: i64 = 0;
    for (0..ADDITION_PASSES) |_| {
        result = treeAdd(nodes[0..], root);
    }
    return result;
}
