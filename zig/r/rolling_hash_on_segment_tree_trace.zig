const MAX_N: usize = 20;
const MAX_Q: usize = 20;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 123;
const TREE_BASE: usize = 32;
const TREE_SIZE: usize = 2 * TREE_BASE;
const BASE: i64 = 911_382_323;
const MODULUS: i64 = 1_000_000_007;

const HashNode = struct {
    hash: i64 = 0,
    length: usize = 0,
};

fn combine(left: HashNode, right: HashNode, powers: *const [MAX_N + 1]i64) HashNode {
    return .{
        .hash = (left.hash * powers[right.length] + right.hash) % MODULUS,
        .length = left.length + right.length,
    };
}

fn rangeHash(
    tree: *const [TREE_SIZE]HashNode,
    powers: *const [MAX_N + 1]i64,
    left: usize,
    right: usize,
) HashNode {
    var left_index = TREE_BASE + left;
    var right_index = TREE_BASE + right;
    var left_result = HashNode{};
    var right_result = HashNode{};
    while (left_index < right_index) {
        if (left_index % 2 == 1) {
            left_result = combine(left_result, tree[left_index], powers);
            left_index += 1;
        }
        if (right_index % 2 == 1) {
            right_index -= 1;
            right_result = combine(tree[right_index], right_result, powers);
        }
        left_index /= 2;
        right_index /= 2;
    }
    return combine(left_result, right_result, powers);
}

fn setSymbol(
    tree: *[TREE_SIZE]HashNode,
    powers: *const [MAX_N + 1]i64,
    index: usize,
    symbol: i64,
) void {
    var node = TREE_BASE + index;
    tree[node] = .{ .hash = symbol, .length = 1 };
    node /= 2;
    while (node > 0) {
        tree[node] = combine(tree[2 * node], tree[2 * node + 1], powers);
        node /= 2;
    }
}

export fn rolling_hash_on_segment_tree_trace(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 0 or n_value > 20 or q_value < 0 or q_value > 20) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + n + 5 * q) return -1;
    const query_start = 2 + n;
    for (0..n) |index| {
        const symbol = input[2 + index];
        if (symbol < 0 or symbol > 25) return -1;
    }

    var powers: [MAX_N + 1]i64 = @splat(0);
    powers[0] = 1;
    for (1..MAX_N + 1) |exponent| {
        powers[exponent] = powers[exponent - 1] * BASE % MODULUS;
    }
    var tree: [TREE_SIZE]HashNode = @splat(.{});
    for (0..n) |index| tree[TREE_BASE + index] = .{ .hash = input[2 + index], .length = 1 };
    var node = TREE_BASE - 1;
    while (node > 0) : (node -= 1) {
        tree[node] = combine(tree[2 * node], tree[2 * node + 1], &powers);
    }

    var score: i64 = 0;
    for (0..q) |operation| {
        const offset = query_start + 5 * operation;
        const opcode = input[offset];
        const a = input[offset + 1];
        const b = input[offset + 2];
        const c = input[offset + 3];
        const d = input[offset + 4];
        var response: i64 = 0;
        if (opcode == 0) {
            if (a < 0 or a >= n_value or b < 0 or b > 25 or c != 0 or d != 0) return -1;
            setSymbol(&tree, &powers, @intCast(a), b);
        } else if (opcode == 1) {
            if (a < 0 or a > b or b > n_value or c < 0 or c > d or d > n_value) return -1;
            if (b - a == d - c) {
                const first = rangeHash(&tree, &powers, @intCast(a), @intCast(b));
                const second = rangeHash(&tree, &powers, @intCast(c), @intCast(d));
                response = @intFromBool(first.hash == second.hash);
            }
        } else {
            return -1;
        }
        score += (@as(i64, @intCast(operation)) + 1) * (opcode * 2 + response + 1);
    }
    return score;
}
