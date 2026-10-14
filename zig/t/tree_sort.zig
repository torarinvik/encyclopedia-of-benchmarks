/// Binary-search-tree sort with iterative insertion and in-order traversal.
const MAX_VALUES = 1024;

export fn tree_sort(values: [*]i64, length: usize) void {
    if (length > MAX_VALUES) return;
    var keys: [MAX_VALUES]i64 = undefined;
    var left: [MAX_VALUES]usize = undefined;
    var right: [MAX_VALUES]usize = undefined;
    var stack: [MAX_VALUES]usize = undefined;
    var root = length;
    for (0..length) |index| {
        keys[index] = values[index];
        left[index] = length;
        right[index] = length;
        if (root == length) { root = index; continue; }
        var node = root;
        while (true) {
            if (keys[index] < keys[node]) {
                if (left[node] == length) { left[node] = index; break; }
                node = left[node];
            } else {
                if (right[node] == length) { right[node] = index; break; }
                node = right[node];
            }
        }
    }
    var current = root;
    var stack_size: usize = 0;
    var output: usize = 0;
    while (current != length or stack_size > 0) {
        while (current != length) {
            stack[stack_size] = current;
            stack_size += 1;
            current = left[current];
        }
        stack_size -= 1;
        current = stack[stack_size];
        values[output] = keys[current];
        output += 1;
        current = right[current];
    }
}
