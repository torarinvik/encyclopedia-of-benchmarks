const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 16;
const MAX_NODES: usize = MAX_VERTICES + MAX_EDGES;
const LOG_LEVELS: usize = 5;
const MAX_INPUT_LENGTH: usize = 67;

const Edge = struct {
    from: usize = 0,
    to: usize = 0,
    weight: i64 = 0,
    original_index: usize = 0,
};

fn findRoot(parent: *[MAX_VERTICES]usize, start: usize) usize {
    var root = start;
    while (parent[root] != root) root = parent[root];
    var vertex = start;
    while (parent[vertex] != vertex) {
        const next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    return root;
}

fn edgeGreater(left: Edge, right: Edge) bool {
    return left.weight > right.weight
        or (left.weight == right.weight and left.original_index > right.original_index);
}

export fn kruskal_reconstruction_tree_bottleneck(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    const n_value = input[0];
    const m_value = input[1];
    const q_value = input[2];
    if (n_value < 1 or n_value > 8 or m_value < 0 or m_value > 16
        or q_value < 1 or q_value > 8) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    const q: usize = @intCast(q_value);
    const query_offset = 3 + 3 * m;
    if (length != query_offset + 2 * q) return -1;

    var edges: [MAX_EDGES]Edge = @splat(.{});
    for (0..m) |edge_index| {
        const from_value = input[3 + 3 * edge_index];
        const to_value = input[4 + 3 * edge_index];
        const weight = input[5 + 3 * edge_index];
        if (from_value < 0 or from_value >= @as(i64, @intCast(n))
            or to_value < 0 or to_value >= @as(i64, @intCast(n))
            or weight < 0 or weight > 1_000_000) return -1;
        edges[edge_index] = .{
            .from = @intCast(from_value),
            .to = @intCast(to_value),
            .weight = weight,
            .original_index = edge_index,
        };
    }
    for (0..q) |query| {
        for (0..2) |side| {
            const vertex = input[query_offset + 2 * query + side];
            if (vertex < 0 or vertex >= @as(i64, @intCast(n))) return -1;
        }
    }

    for (1..m) |index| {
        const edge = edges[index];
        var position = index;
        while (position > 0 and edgeGreater(edges[position - 1], edge)) {
            edges[position] = edges[position - 1];
            position -= 1;
        }
        edges[position] = edge;
    }

    var dsu_parent: [MAX_VERTICES]usize = @splat(0);
    var dsu_size: [MAX_VERTICES]usize = @splat(0);
    var tree_root: [MAX_VERTICES]usize = @splat(0);
    for (0..n) |vertex| {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
        tree_root[vertex] = vertex;
    }
    var tree_parent: [MAX_NODES]i32 = @splat(-1);
    var children: [MAX_NODES][2]i32 = @splat(@splat(-1));
    var labels: [MAX_NODES]i64 = @splat(0);
    var node_count = n;
    for (edges[0..m]) |edge| {
        var left_root = findRoot(&dsu_parent, edge.from);
        var right_root = findRoot(&dsu_parent, edge.to);
        if (left_root == right_root) continue;
        const merged_node = node_count;
        node_count += 1;
        children[merged_node] = .{ @intCast(tree_root[left_root]), @intCast(tree_root[right_root]) };
        labels[merged_node] = edge.weight;
        tree_parent[tree_root[left_root]] = @intCast(merged_node);
        tree_parent[tree_root[right_root]] = @intCast(merged_node);
        if (dsu_size[left_root] < dsu_size[right_root]) {
            const temporary = left_root;
            left_root = right_root;
            right_root = temporary;
        }
        dsu_parent[right_root] = left_root;
        dsu_size[left_root] += dsu_size[right_root];
        tree_root[left_root] = merged_node;
    }

    var depth: [MAX_NODES]usize = @splat(0);
    var ancestors: [LOG_LEVELS][MAX_NODES]usize = @splat(@splat(0));
    for (0..node_count) |root| {
        if (tree_parent[root] >= 0) continue;
        ancestors[0][root] = root;
        var stack: [MAX_NODES]usize = @splat(0);
        var top: usize = 1;
        stack[0] = root;
        while (top > 0) {
            top -= 1;
            const node = stack[top];
            for (0..2) |side| {
                const child_signed = children[node][side];
                if (child_signed < 0) continue;
                const child: usize = @intCast(child_signed);
                depth[child] = depth[node] + 1;
                ancestors[0][child] = node;
                stack[top] = child;
                top += 1;
            }
        }
    }
    for (1..LOG_LEVELS) |level| {
        for (0..node_count) |node| {
            ancestors[level][node] = ancestors[level - 1][ancestors[level - 1][node]];
        }
    }

    var checksum: i64 = 0;
    for (0..q) |query| {
        const source: usize = @intCast(input[query_offset + 2 * query]);
        const destination: usize = @intCast(input[query_offset + 2 * query + 1]);
        var answer: i64 = 0;
        if (source == destination) {
            answer = 0;
        } else if (findRoot(&dsu_parent, source) != findRoot(&dsu_parent, destination)) {
            answer = -1;
        } else {
            var left = source;
            var right = destination;
            if (depth[left] < depth[right]) {
                const temporary = left;
                left = right;
                right = temporary;
            }
            const difference = depth[left] - depth[right];
            for (0..LOG_LEVELS) |level| {
                if (difference & (@as(usize, 1) << @intCast(level)) != 0) {
                    left = ancestors[level][left];
                }
            }
            if (left != right) {
                var level = LOG_LEVELS;
                while (level > 0) {
                    level -= 1;
                    if (ancestors[level][left] != ancestors[level][right]) {
                        left = ancestors[level][left];
                        right = ancestors[level][right];
                    }
                }
                left = ancestors[0][left];
            }
            answer = labels[left];
        }
        checksum += @as(i64, @intCast(query + 1)) * (answer + 2);
    }
    return checksum;
}
