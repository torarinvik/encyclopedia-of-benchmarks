const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_VALUES: usize = 2 + 3 * MAX_OPERATIONS;
const OBSERVED_OFFSET: i64 = 1_000_003;

fn findRoot(parent: *[MAX_ITEMS]usize, item: usize) usize {
    var current = item;
    while (parent[current] != current) {
        parent[current] = parent[parent[current]];
        current = parent[current];
    }
    return current;
}

export fn union_find_benchmark(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_VALUES) return -1;
    const item_count_value = values[0];
    const operation_count_value = values[1];
    if (item_count_value < 1 or item_count_value > MAX_ITEMS or
        operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;
    const item_count: usize = @intCast(item_count_value);
    const operation_count: usize = @intCast(operation_count_value);
    if (length != 2 + 3 * operation_count) return -1;

    for (0..operation_count) |operation| {
        const position = 2 + 3 * operation;
        const opcode = values[position];
        const first = values[position + 1];
        const second = values[position + 2];
        if (opcode == 0 or opcode == 1) {
            if (first < 0 or first >= item_count_value or second < 0 or second >= item_count_value) return -1;
        } else if (opcode == 2) {
            if (first != 0 or second != 0) return -1;
        } else return -1;
    }

    var parent: [MAX_ITEMS]usize = undefined;
    var set_size: [MAX_ITEMS]usize = undefined;
    for (0..item_count) |i| {
        parent[i] = i;
        set_size[i] = 1;
    }
    var components = item_count;
    var connected_pairs: i64 = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const position = 2 + 3 * operation;
        const opcode = values[position];
        const first: usize = @intCast(values[position + 1]);
        const second: usize = @intCast(values[position + 2]);
        var observed: i64 = 0;
        if (opcode == 0) {
            const first_root = findRoot(&parent, first);
            const second_root = findRoot(&parent, second);
            if (first_root != second_root) {
                connected_pairs += @as(i64, @intCast(set_size[first_root] * set_size[second_root]));
                if (set_size[first_root] < set_size[second_root]) {
                    parent[first_root] = second_root;
                    set_size[second_root] += set_size[first_root];
                } else {
                    parent[second_root] = first_root;
                    set_size[first_root] += set_size[second_root];
                }
                components -= 1;
                observed = 1;
            }
        } else if (opcode == 1) {
            observed = @intFromBool(findRoot(&parent, first) == findRoot(&parent, second));
        } else {
            observed = @intCast(components);
        }
        checksum += @as(i64, @intCast(operation + 1)) * (observed + OBSERVED_OFFSET);
    }
    return checksum + connected_pairs;
}
