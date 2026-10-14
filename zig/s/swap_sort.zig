/// Count minimum swaps needed to order a distinct-value array.
const MAX_VALUES = 256;

fn positionLess(keys: []const i64, order: []const usize, left: usize, right: usize) bool {
    const a = order[left];
    const b = order[right];
    return keys[a] < keys[b] or (keys[a] == keys[b] and a < b);
}

fn siftDown(keys: []const i64, order: []usize, heap_length: usize, start_root: usize) void {
    var root = start_root;
    while (root < heap_length / 2) {
        var child = root * 2 + 1;
        if (child + 1 < heap_length and positionLess(keys, order, child, child + 1)) child += 1;
        if (!positionLess(keys, order, root, child)) break;
        const temporary = order[root]; order[root] = order[child]; order[child] = temporary;
        root = child;
    }
}

export fn swap_sort(values: [*]const i64, length: usize) i64 {
    if (length > MAX_VALUES) return -1;
    var keys: [MAX_VALUES]i64 = undefined;
    var order: [MAX_VALUES]usize = undefined;
    var visited: [MAX_VALUES]bool = @splat(false);
    for (0..length) |index| { keys[index] = values[index]; order[index] = index; }
    var start = length / 2;
    while (start > 0) { start -= 1; siftDown(keys[0..], order[0..], length, start); }
    var finish = length;
    while (finish > 1) {
        finish -= 1;
        const temporary = order[0]; order[0] = order[finish]; order[finish] = temporary;
        siftDown(keys[0..], order[0..], finish, 0);
    }
    if (length > 1) {
        for (1..length) |index| {
            if (keys[order[index - 1]] == keys[order[index]]) return -1;
        }
    }
    var swaps: usize = 0;
    for (0..length) |first| {
        if (visited[first]) continue;
        var node = first;
        var cycle_length: usize = 0;
        while (!visited[node]) { visited[node] = true; node = order[node]; cycle_length += 1; }
        if (cycle_length > 0) swaps += cycle_length - 1;
    }
    return @intCast(swaps);
}
