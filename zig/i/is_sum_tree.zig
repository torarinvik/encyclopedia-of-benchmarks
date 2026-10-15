const MAX_NODES = 400;
const INVALID_RESULT: i64 = -9_000_000_000_000_000_000;

fn subtreeSum(nodes: [*]const i64, index: i64) i64 {
    if (index < 0) return 0;
    const base: usize = @intCast(index) * 3;
    return nodes[base] + subtreeSum(nodes, nodes[base+1]) + subtreeSum(nodes, nodes[base+2]);
}
fn checkNode(nodes: [*]const i64, index: i64) bool {
    const base: usize = @intCast(index) * 3;
    const value=nodes[base]; const left=nodes[base+1]; const right=nodes[base+2];
    if (left == -1 and right == -1) return true;
    const left_sum=subtreeSum(nodes,left); const right_sum=subtreeSum(nodes,right);
    const left_ok=left == -1 or checkNode(nodes,left);
    const right_ok=right == -1 or checkNode(nodes,right);
    return value == left_sum + right_sum and left_ok and right_ok;
}

export fn is_sum_tree(nodes: [*c]const i64, count: usize, root: i64) i64 {
    if (nodes == null or count == 0 or count > MAX_NODES or root < 0 or @as(u64,@intCast(root)) >= count) return INVALID_RESULT;
    var seen: [MAX_NODES]bool = @splat(false);
    var stack: [MAX_NODES * 2]i64 = @splat(0);
    var top: usize = 0; stack[top] = root; top += 1;
    while (top > 0) {
        top -= 1; const index = stack[top];
        if (index < 0 or @as(u64,@intCast(index)) >= count or seen[@intCast(index)]) return INVALID_RESULT;
        seen[@intCast(index)] = true;
        const base: usize = @intCast(index) * 3;
        const value=nodes[base]; const left=nodes[base+1]; const right=nodes[base+2];
        if (value < -1_000_000_000 or value > 1_000_000_000 or left < -1 or right < -1 or
            (left >= 0 and @as(u64,@intCast(left)) >= count) or (right >= 0 and @as(u64,@intCast(right)) >= count)) return INVALID_RESULT;
        if (left >= 0) { stack[top] = left; top += 1; }
        if (right >= 0) { stack[top] = right; top += 1; }
    }
    return if (checkNode(nodes,root)) 1 else 0;
}
