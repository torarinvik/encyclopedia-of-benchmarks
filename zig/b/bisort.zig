const MIN_SIZE: i64 = 2;
const MAX_SIZE: i64 = 1024;
const MAX_NODES: usize = 1023;
const MODULUS: i32 = 10000;
const MULTIPLIER: i32 = 31415821;
const VALUE_RANGE: i32 = 100;

const Node = struct {
    value: i32,
    left: i32,
    right: i32,
};

fn multiply(p: i32, q: i32) i32 {
    const p_high = @divTrunc(p, MODULUS);
    const p_low = @rem(p, MODULUS);
    const q_high = @divTrunc(q, MODULUS);
    const q_low = @rem(q, MODULUS);
    return @rem(p_low * q_high + p_high * q_low, MODULUS) * MODULUS + p_low * q_low;
}

fn nextRandom(seed: i32) i32 { return multiply(seed, MULTIPLIER) + 1; }

fn skipRandom(seed_value: i32, count: i32) i32 {
    var seed = seed_value;
    var i: i32 = 0;
    while (i < count) : (i += 1) seed = nextRandom(seed);
    return seed;
}

fn makeTree(nodes: []Node, used: *usize, size: i32, seed_value: i32) i32 {
    if (size <= 1) return -1;
    const seed = nextRandom(seed_value);
    const index: i32 = @intCast(used.*);
    used.* += 1;
    nodes[@intCast(index)].value = @rem(seed, VALUE_RANGE);
    const half = @divTrunc(size, 2);
    nodes[@intCast(index)].left = makeTree(nodes, used, half, seed);
    nodes[@intCast(index)].right = makeTree(nodes, used, half, skipRandom(seed, size + 1));
    return index;
}

fn swapLeft(nodes: []Node, left: i32, right: i32, left_left: i32, right_left: i32,
            left_value: i32, right_value: i32) void {
    nodes[@intCast(right)].value = left_value;
    nodes[@intCast(right)].left = left_left;
    nodes[@intCast(left)].left = right_left;
    nodes[@intCast(left)].value = right_value;
}

fn swapRight(nodes: []Node, left: i32, right: i32, left_right: i32, right_right: i32,
             left_value: i32, right_value: i32) void {
    nodes[@intCast(right)].value = left_value;
    nodes[@intCast(right)].right = left_right;
    nodes[@intCast(left)].right = right_right;
    nodes[@intCast(left)].value = right_value;
}

fn merge(nodes: []Node, root: i32, spill_value: i32, direction: i32) i32 {
    var spill = spill_value;
    var root_value = nodes[@intCast(root)].value;
    var left = nodes[@intCast(root)].left;
    var right = nodes[@intCast(root)].right;
    const right_exchange = (root_value > spill) != (direction != 0);
    if (right_exchange) {
        nodes[@intCast(root)].value = spill;
        spill = root_value;
    }
    while (left >= 0) {
        const left_value = nodes[@intCast(left)].value;
        const left_left = nodes[@intCast(left)].left;
        const left_right = nodes[@intCast(left)].right;
        const right_value = nodes[@intCast(right)].value;
        const right_left = nodes[@intCast(right)].left;
        const right_right = nodes[@intCast(right)].right;
        const element_exchange = (left_value > right_value) != (direction != 0);
        if (right_exchange) {
            if (element_exchange) {
                swapRight(nodes, left, right, left_right, right_right, left_value, right_value);
                left = left_left;
                right = right_left;
            } else {
                left = left_right;
                right = right_right;
            }
        } else if (element_exchange) {
            swapLeft(nodes, left, right, left_left, right_left, left_value, right_value);
            left = left_right;
            right = right_right;
        } else {
            left = left_left;
            right = right_left;
        }
    }
    if (nodes[@intCast(root)].left >= 0) {
        const left_root = nodes[@intCast(root)].left;
        const right_root = nodes[@intCast(root)].right;
        root_value = nodes[@intCast(root)].value;
        nodes[@intCast(root)].value = merge(nodes, left_root, root_value, direction);
        spill = merge(nodes, right_root, spill, direction);
    }
    return spill;
}

fn sortTree(nodes: []Node, root: i32, spill_value: i32, direction: i32) i32 {
    var spill = spill_value;
    if (nodes[@intCast(root)].left < 0) {
        if ((nodes[@intCast(root)].value > spill) != (direction != 0)) {
            const value = nodes[@intCast(root)].value;
            nodes[@intCast(root)].value = spill;
            spill = value;
        }
        return spill;
    }
    const left = nodes[@intCast(root)].left;
    const right = nodes[@intCast(root)].right;
    const value = nodes[@intCast(root)].value;
    nodes[@intCast(root)].value = sortTree(nodes, left, value, direction);
    spill = sortTree(nodes, right, spill, if (direction == 0) 1 else 0);
    return merge(nodes, root, spill, direction);
}

fn checksum(nodes: []const Node, index: i32, position: *i64, sum: *i64) void {
    if (index < 0) return;
    checksum(nodes, nodes[@intCast(index)].left, position, sum);
    position.* += 1;
    sum.* += position.* * @as(i64, nodes[@intCast(index)].value);
    checksum(nodes, nodes[@intCast(index)].right, position, sum);
}

export fn bisort(size: i64) i64 {
    if (size < MIN_SIZE or size > MAX_SIZE) return -1;
    var nodes: [MAX_NODES]Node = undefined;
    var used: usize = 0;
    const root = makeTree(nodes[0..], &used, @intCast(size), 12345768);
    var spill = @rem(nextRandom(245867), VALUE_RANGE);
    spill = sortTree(nodes[0..], root, spill, 0);
    spill = sortTree(nodes[0..], root, spill, 1);
    var position: i64 = 0;
    var sum: i64 = 0;
    checksum(nodes[0..], root, &position, &sum);
    position += 1;
    return sum + position * @as(i64, spill);
}
