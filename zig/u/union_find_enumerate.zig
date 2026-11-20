const MAX_ITEMS: usize = 16;
const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 99;

fn findRoot(parent: *[MAX_ITEMS]i64, item: usize) usize {
    var root = item;
    while (parent[root] >= 0) root = @intCast(parent[root]);
    var current = item;
    while (current != root) {
        const next_item: usize = @intCast(parent[current]);
        parent[current] = @intCast(root);
        current = next_item;
    }
    return root;
}

fn componentMask(successor: *const [MAX_ITEMS]i64, start: usize) i64 {
    var mask: u64 = 0;
    var item = start;
    while (true) {
        mask |= @as(u64, 1) << @intCast(item);
        item = @intCast(successor[item]);
        if (item == start) break;
    }
    return @intCast(mask);
}

export fn union_find_enumerate(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const item_count_value = input[0];
    const operation_count_value = input[1];
    if (item_count_value < 1 or item_count_value > MAX_ITEMS or
        operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;
    const item_count: usize = @intCast(item_count_value);
    const operation_count: usize = @intCast(operation_count_value);
    if (length != 2 + 3 * operation_count) return -1;

    for (0..operation_count) |operation| {
        const position = 2 + 3 * operation;
        const opcode = input[position];
        const first = input[position + 1];
        const second = input[position + 2];
        if (opcode == 0) {
            if (first < 0 or first >= item_count_value or second < 0 or second >= item_count_value) return -1;
        } else if (opcode == 1) {
            if (first < 0 or first >= item_count_value or second != 0) return -1;
        } else return -1;
    }

    var parent: [MAX_ITEMS]i64 = @splat(-1);
    var successor: [MAX_ITEMS]i64 = undefined;
    for (0..item_count) |item| successor[item] = @intCast(item);
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const position = 2 + 3 * operation;
        const opcode = input[position];
        const first: usize = @intCast(input[position + 1]);
        var observed: i64 = 0;
        if (opcode == 0) {
            var left = findRoot(&parent, first);
            var right = findRoot(&parent, @intCast(input[position + 2]));
            if (left != right) {
                if (parent[left] > parent[right]) {
                    const temporary = left;
                    left = right;
                    right = temporary;
                }
                parent[left] += parent[right];
                parent[right] = @intCast(left);
                const temporary_next = successor[left];
                successor[left] = successor[right];
                successor[right] = temporary_next;
                observed = 1;
            }
        } else {
            observed = componentMask(&successor, first);
        }
        checksum += @as(i64, @intCast(operation + 1)) * (observed + 1);
    }
    return checksum;
}
