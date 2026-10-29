const MAX_TREES: usize = 16;
const MAX_TREE_VERTICES: usize = 32;
const MAX_TOTAL_VERTICES: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_TREES * MAX_TREE_VERTICES;

const Signature = struct {
    child_count: usize,
    child_types: [MAX_TREE_VERTICES]usize,
};

fn internSignature(signatures: *[MAX_TOTAL_VERTICES]Signature,
    signature_count: *usize, children: *const [MAX_TREE_VERTICES]usize,
    child_count: usize) usize {
    for (0..signature_count.*) |signature| {
        if (signatures[signature].child_count != child_count) continue;
        var index: usize = 0;
        while (index < child_count and signatures[signature].child_types[index] == children[index]) : (index += 1) {}
        if (index == child_count) return signature;
    }
    if (signature_count.* >= MAX_TOTAL_VERTICES) return MAX_TOTAL_VERTICES;
    const result = signature_count.*;
    signatures[result].child_count = child_count;
    for (0..child_count) |index| signatures[result].child_types[index] = children[index];
    signature_count.* += 1;
    return result;
}

fn canonicalRootType(adjacency: *const [MAX_TREE_VERTICES]u32, n: usize,
    root: usize, signatures: *[MAX_TOTAL_VERTICES]Signature,
    signature_count: *usize) i64 {
    var parent = [_]usize{MAX_TREE_VERTICES} ** MAX_TREE_VERTICES;
    var order: [MAX_TREE_VERTICES]usize = undefined;
    var stack: [MAX_TREE_VERTICES]usize = undefined;
    var nodeType: [MAX_TREE_VERTICES]usize = undefined;
    var visited = [_]bool{false} ** MAX_TREE_VERTICES;
    parent[root] = root;
    visited[root] = true;
    var stack_size: usize = 1;
    var order_size: usize = 0;
    stack[0] = root;
    while (stack_size != 0) {
        stack_size -= 1;
        const vertex = stack[stack_size];
        order[order_size] = vertex;
        order_size += 1;
        for (0..n) |neighbor| {
            const bit = @as(u32, 1) << @intCast(neighbor);
            if ((adjacency[vertex] & bit) == 0 or neighbor == parent[vertex]) continue;
            if (visited[neighbor]) return -1;
            visited[neighbor] = true;
            parent[neighbor] = vertex;
            stack[stack_size] = neighbor;
            stack_size += 1;
        }
    }
    if (order_size != n) return -1;

    var reverse = order_size;
    while (reverse > 0) {
        reverse -= 1;
        const vertex = order[reverse];
        var children: [MAX_TREE_VERTICES]usize = undefined;
        var child_count: usize = 0;
        for (0..n) |candidate| {
            if (candidate != vertex and parent[candidate] == vertex) {
                children[child_count] = nodeType[candidate];
                child_count += 1;
            }
        }
        var index: usize = 1;
        while (index < child_count) : (index += 1) {
            const value = children[index];
            var place = index;
            while (place > 0 and children[place - 1] > value) : (place -= 1) {
                children[place] = children[place - 1];
            }
            children[place] = value;
        }
        nodeType[vertex] = internSignature(signatures, signature_count, &children, child_count);
        if (nodeType[vertex] >= MAX_TOTAL_VERTICES) return -1;
    }
    return @intCast(nodeType[root]);
}

export fn rooted_tree_isomorphism_classification(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_TREES))) return -1;
    const tree_count: usize = @intCast(input[0]);
    var signatures: [MAX_TOTAL_VERTICES]Signature = undefined;
    var signature_count: usize = 0;
    var root_types: [MAX_TREES]usize = undefined;
    var labels: [MAX_TREES]u8 = undefined;
    var position: usize = 1;
    var total_vertices: usize = 0;
    var class_count: usize = 0;

    for (0..tree_count) |tree| {
        if (position + 2 > length) return -1;
        const n_value = input[position];
        const root_value = input[position + 1];
        position += 2;
        if (n_value < 1 or n_value > @as(i64, @intCast(MAX_TREE_VERTICES)) or
            root_value < 0 or root_value >= n_value) return -1;
        const n: usize = @intCast(n_value);
        total_vertices += n;
        if (total_vertices > MAX_TOTAL_VERTICES) return -1;
        const edge_count = n - 1;
        if (2 * edge_count > length - position) return -1;
        var adjacency = [_]u32{0} ** MAX_TREE_VERTICES;
        for (0..edge_count) |_| {
            const left_value = input[position];
            const right_value = input[position + 1];
            position += 2;
            if (left_value < 0 or right_value < 0 or left_value >= n_value or
                right_value >= n_value or left_value == right_value) return -1;
            const left: usize = @intCast(left_value);
            const right: usize = @intCast(right_value);
            const left_bit = @as(u32, 1) << @intCast(left);
            const right_bit = @as(u32, 1) << @intCast(right);
            if ((adjacency[left] & right_bit) != 0) return -1;
            adjacency[left] |= right_bit;
            adjacency[right] |= left_bit;
        }
        const root_type = canonicalRootType(&adjacency, n, @intCast(root_value), &signatures, &signature_count);
        if (root_type < 0) return -1;
        root_types[tree] = @intCast(root_type);
        var prior: usize = 0;
        while (prior < tree and root_types[prior] != root_types[tree]) : (prior += 1) {}
        if (prior < tree) {
            labels[tree] = labels[prior];
        } else {
            labels[tree] = @intCast(class_count);
            class_count += 1;
        }
    }
    if (position != length) return -1;
    if (output_opt == null or output_capacity < tree_count) return -2;
    const output = output_opt.?;
    for (0..tree_count) |tree| output[tree] = labels[tree];
    return @intCast(tree_count);
}
