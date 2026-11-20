const MAX_N: usize = 8;
const MAX_LEN: usize = 35;
const INF: i64 = 1_000_000;

const Tree = struct {
    n: usize = 0,
    labels: [MAX_N]i64 = @splat(0),
    children: [MAX_N][MAX_N]usize = @splat(@splat(0)),
    child_count: [MAX_N]usize = @splat(0),
};
const Post = struct {
    n: usize = 0,
    labels: [MAX_N + 1]i64 = @splat(0),
    leftmost: [MAX_N + 1]usize = @splat(0),
};

fn postVisit(tree: *const Tree, vertex: usize, post: *Post) usize {
    var left: usize = 0;
    for (0..tree.child_count[vertex]) |k| {
        const child_left = postVisit(tree, tree.children[vertex][k], post);
        if (k == 0) left = child_left;
    }
    post.n += 1;
    const id = post.n;
    post.labels[id] = tree.labels[vertex];
    post.leftmost[id] = if (left == 0) id else left;
    return post.leftmost[id];
}

fn readTree(input: [*]const i64, position: *usize, n: usize) ?Tree {
    var tree = Tree{ .n = n };
    for (0..n) |v| {
        const label = input[position.*]; position.* += 1;
        if (label < 0 or label > 3) return null;
        tree.labels[v] = label;
    }
    var stack: [MAX_N]usize = @splat(0);
    var top: isize = 0;
    for (0..n) |v| {
        const parent = input[position.*]; position.* += 1;
        if (v == 0) {
            if (parent != -1) return null;
            stack[0] = 0;
            continue;
        }
        if (parent < 0 or parent >= @as(i64, @intCast(v))) return null;
        while (top >= 0 and stack[@intCast(top)] != @as(usize, @intCast(parent))) : (top -= 1) {}
        if (top < 0) return null;
        const p: usize = @intCast(parent);
        tree.children[p][tree.child_count[p]] = v;
        tree.child_count[p] += 1;
        top += 1; stack[@intCast(top)] = v;
    }
    return tree;
}

fn distance(a: *const Tree, b: *const Tree) i64 {
    var pa = Post{}; var pb = Post{};
    _ = postVisit(a, 0, &pa); _ = postVisit(b, 0, &pb);
    var key_a: [MAX_N + 1]usize = @splat(0);
    var key_b: [MAX_N + 1]usize = @splat(0);
    for (1..pa.n + 1) |i| key_a[pa.leftmost[i]] = i;
    for (1..pb.n + 1) |j| key_b[pb.leftmost[j]] = j;
    var td: [MAX_N + 1][MAX_N + 1]i64 = @splat(@splat(0));
    for (1..pa.n + 1) |ra| {
        if (key_a[pa.leftmost[ra]] != ra) continue;
        for (1..pb.n + 1) |rb| {
            if (key_b[pb.leftmost[rb]] != rb) continue;
            const sa = pa.leftmost[ra]; const sb = pb.leftmost[rb];
            var fd: [MAX_N + 1][MAX_N + 1]i64 = @splat(@splat(INF));
            fd[sa - 1][sb - 1] = 0;
            for (sa..ra + 1) |x| fd[x][sb - 1] = fd[x - 1][sb - 1] + 1;
            for (sb..rb + 1) |y| fd[sa - 1][y] = fd[sa - 1][y - 1] + 1;
            for (sa..ra + 1) |x| {
                for (sb..rb + 1) |y| {
                    const del = fd[x - 1][y] + 1;
                    const ins = fd[x][y - 1] + 1;
                    if (pa.leftmost[x] == sa and pb.leftmost[y] == sb) {
                        const rename = fd[x - 1][y - 1] + @as(i64, if (pa.labels[x] != pb.labels[y]) 1 else 0);
                        const best = @min(@min(del, ins), rename);
                        fd[x][y] = best; td[x][y] = best;
                    } else {
                        const join = fd[pa.leftmost[x] - 1][pb.leftmost[y] - 1] + td[x][y];
                        fd[x][y] = @min(@min(del, ins), join);
                    }
                }
            }
        }
    }
    return td[pa.n][pb.n];
}

fn solve(input: [*]const i64, length: usize) i64 {
    if (length < 6 or length > MAX_LEN) return -1;
    const n1v = input[0]; const n2v = input[1];
        if (n1v < 1 or n1v > @as(i64, @intCast(MAX_N)) or n2v < 1 or n2v > @as(i64, @intCast(MAX_N))) return -1;
    const n1: usize = @intCast(n1v); const n2: usize = @intCast(n2v);
    if (length != 2 + 2 * n1 + 2 * n2) return -1;
    var position: usize = 2;
    const a = readTree(input, &position, n1) orelse return -1;
    const b = readTree(input, &position, n2) orelse return -1;
    return distance(&a, &b);
}

export fn ordered_tree_edit_distance_zhang_shasha(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 6 or length > MAX_LEN) return -1;
    return solve(input_opt.?, length);
}
