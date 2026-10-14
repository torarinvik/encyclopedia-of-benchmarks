/// Bounded unbalanced binary search tree with an index-based node pool.
export fn binary_search_tree_benchmark(values: [*]const i64, length: usize) i64 {
    if (length > 1024 or length % 2 != 0) return -1;
    const operation_count = length / 2;
    const none: usize = 256;
    var key: [256]i64 = undefined;
    var left: [256]usize = undefined;
    var right: [256]usize = undefined;
    var free_next: [256]usize = undefined;
    for (0..256) |i| { free_next[i] = i + 1; }
    var free_head: usize = 0; var root: usize = none; var count: usize = 0; var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const opcode = values[2 * operation]; const payload = values[2 * operation + 1];
        var observed: i64 = 0;
        if (opcode == 0) {
            if (payload < -1_000_000 or payload > 1_000_000) return -1;
            var parent: usize = none; var node = root;
            while (node != none and key[node] != payload) { parent = node; node = if (payload < key[node]) left[node] else right[node]; }
            if (node == none) {
                if (count == 256 or free_head == none) return -1;
                node = free_head; free_head = free_next[node]; key[node] = payload; left[node] = none; right[node] = none;
                if (parent == none) { root = node; } else if (payload < key[parent]) { left[parent] = node; } else { right[parent] = node; }
                count += 1; observed = 1;
            }
        } else if (opcode == 1) {
            if (payload < -1_000_000 or payload > 1_000_000) return -1;
            var parent: usize = none; var node = root;
            while (node != none and key[node] != payload) { parent = node; node = if (payload < key[node]) left[node] else right[node]; }
            observed = if (node == none) 0 else 1;
            if (node != none) {
                if (left[node] != none and right[node] != none) {
                    var pred_parent = node; var pred = left[node];
                    while (right[pred] != none) { pred_parent = pred; pred = right[pred]; }
                    key[node] = key[pred]; parent = pred_parent; node = pred;
                }
                const child = if (left[node] != none) left[node] else right[node];
                if (parent == none) { root = child; } else if (left[parent] == node) { left[parent] = child; } else { right[parent] = child; }
                free_next[node] = free_head; free_head = node; count -= 1;
            }
        } else if (opcode == 2) {
            if (payload < -1_000_000 or payload > 1_000_000) return -1;
            var node = root;
            while (node != none and key[node] != payload) { node = if (payload < key[node]) left[node] else right[node]; }
            observed = if (node == none) 0 else 1;
        } else if (opcode == 3 or opcode == 4) {
            if (payload != 0 or root == none) return -1;
            var node = root;
            if (opcode == 3) { while (left[node] != none) { node = left[node]; } }
            else { while (right[node] != none) { node = right[node]; } }
            observed = key[node];
        } else if (opcode == 5) {
            if (payload != 0) return -1;
            observed = @intCast(count);
        } else return -1;
        checksum += (@as(i64, @intCast(operation)) + 1) * (observed + 1_000_000);
    }
    var stack: [256]usize = undefined; var top: usize = 0; var node = root; var index: usize = 0;
    while (node != none or top != 0) {
        while (node != none) { stack[top] = node; top += 1; node = left[node]; }
        top -= 1; node = stack[top];
        checksum += (@as(i64, @intCast(operation_count + index)) + 1) * (key[node] + 1_000_000);
        index += 1; node = right[node];
    }
    return checksum;
}
