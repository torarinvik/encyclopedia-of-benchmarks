const MAX_NODES: usize = 64;
const MAX_INPUT_LENGTH: usize = 67;

export fn inorder_successor_of_bst(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const count_value = input[0];
    const target = input[1];
    if (count_value < 0 or count_value > 64 or target < 1 or target > 2_147_483_647) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;

    var keys: [MAX_NODES]i64 = undefined;
    var left: [MAX_NODES]i32 = undefined;
    var right: [MAX_NODES]i32 = undefined;
    for (0..count) |index| {
        const key = input[index + 2];
        if (key < 1 or key > 2_147_483_647) return -1;
        for (0..index) |previous| {
            if (keys[previous] == key) return -1;
        }
        keys[index] = key;
        left[index] = -1;
        right[index] = -1;
    }

    var root: i32 = -1;
    for (0..count) |index| {
        if (root < 0) {
            root = @intCast(index);
            continue;
        }
        var current = root;
        while (true) {
            const current_index: usize = @intCast(current);
            if (keys[index] <= keys[current_index]) {
                if (left[current_index] < 0) {
                    left[current_index] = @intCast(index);
                    break;
                }
                current = left[current_index];
            } else {
                if (right[current_index] < 0) {
                    right[current_index] = @intCast(index);
                    break;
                }
                current = right[current_index];
            }
        }
    }

    var current = root;
    while (current >= 0 and keys[@intCast(current)] != target) {
        const current_index: usize = @intCast(current);
        current = if (target > keys[current_index]) right[current_index] else left[current_index];
    }
    if (current < 0) return 0;
    const current_index: usize = @intCast(current);
    if (right[current_index] >= 0) {
        var successor = right[current_index];
        while (left[@intCast(successor)] >= 0) {
            successor = left[@intCast(successor)];
        }
        return keys[@intCast(successor)];
    }

    var successor: i32 = -1;
    var ancestor = root;
    while (ancestor >= 0 and ancestor != current) {
        const ancestor_index: usize = @intCast(ancestor);
        if (keys[current_index] < keys[ancestor_index]) {
            successor = ancestor;
            ancestor = left[ancestor_index];
        } else {
            ancestor = right[ancestor_index];
        }
    }
    if (successor < 0) return 0;
    return keys[@intCast(successor)];
}
