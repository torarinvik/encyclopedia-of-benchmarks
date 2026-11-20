const MAX_N: usize = 16;
const MAX_NODES: usize = 2 * MAX_N - 1;
const TREE_SIZE: usize = 4 * MAX_N + 4;

fn addRange(node: usize, left: usize, right: usize, ql: usize, qr: usize, delta: i32,
    minimum: []i32, lazy: []i32) void {
    if (ql <= left and right <= qr) {
        minimum[node] += delta;
        lazy[node] += delta;
        return;
    }
    const middle = (left + right) / 2;
    if (lazy[node] != 0) {
        const tag = lazy[node];
        minimum[node * 2] += tag;
        minimum[node * 2 + 1] += tag;
        lazy[node * 2] += tag;
        lazy[node * 2 + 1] += tag;
        lazy[node] = 0;
    }
    if (ql <= middle and qr >= left) addRange(node * 2, left, middle, ql, qr, delta, minimum, lazy);
    if (qr > middle and ql <= right) addRange(node * 2 + 1, middle + 1, right, ql, qr, delta, minimum, lazy);
    minimum[node] = @min(minimum[node * 2], minimum[node * 2 + 1]);
}

fn firstZero(node: usize, left: usize, right: usize, minimum: []i32) usize {
    if (left == right) return left;
    const middle = (left + right) / 2;
    if (minimum[node * 2] == 0) return firstZero(node * 2, left, middle, minimum);
    return firstZero(node * 2 + 1, middle + 1, right, minimum);
}

fn connected(left: usize, right: usize, logs: []usize, range_min: []i32, range_max: []i32) bool {
    const level = logs[right - left + 1];
    const other = right + 1 - (@as(usize, 1) << @intCast(level));
    const low = @min(range_min[level * MAX_N + left], range_min[level * MAX_N + other]);
    const high = @max(range_max[level * MAX_N + left], range_max[level * MAX_N + other]);
    return high - low == @as(i32, @intCast(right - left));
}

export fn divide_combine_tree_incremental(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_N + 2) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N))) return -1;
    if (length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    var permutation = [_]i32{0} ** MAX_N;
    var seen = [_]bool{false} ** MAX_N;
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < 0 or value >= @as(i64, @intCast(n))) return -1;
        const value_index: usize = @intCast(value);
        if (seen[value_index]) return -1;
        permutation[i] = @intCast(value);
        seen[value_index] = true;
    }

    var logs = [_]usize{0} ** (MAX_N + 1);
    for (2..n + 1) |i| logs[i] = logs[i / 2] + 1;
    const levels = logs[n] + 1;
    var range_min = [_]i32{0} ** (MAX_N * MAX_N);
    var range_max = [_]i32{0} ** (MAX_N * MAX_N);
    for (0..n) |i| {
        range_min[i] = permutation[i];
        range_max[i] = permutation[i];
    }
    for (1..levels) |level| {
        const half = @as(usize, 1) << @intCast(level - 1);
        const width = half * 2;
        var start: usize = 0;
        while (start + width <= n) : (start += 1) {
            const a = range_min[(level - 1) * MAX_N + start];
            const b = range_min[(level - 1) * MAX_N + start + half];
            range_min[level * MAX_N + start] = @min(a, b);
            const c = range_max[(level - 1) * MAX_N + start];
            const d = range_max[(level - 1) * MAX_N + start + half];
            range_max[level * MAX_N + start] = @max(c, d);
        }
    }

    var segment_min = [_]i32{0} ** TREE_SIZE;
    var lazy = [_]i32{0} ** TREE_SIZE;
    var node_left = [_]i32{0} ** MAX_NODES;
    var node_right = [_]i32{0} ** MAX_NODES;
    var node_combine = [_]bool{false} ** MAX_NODES;
    var node_last = [_]i32{0} ** MAX_NODES;
    var node_stack = [_]usize{0} ** MAX_N;
    var min_stack = [_]usize{0} ** MAX_N;
    var max_stack = [_]usize{0} ** MAX_N;
    var node_top: usize = 0;
    var min_top: usize = 0;
    var max_top: usize = 0;
    var node_count: usize = 0;
    for (0..n) |end| {
        const value = permutation[end];
        while (min_top > 0 and permutation[min_stack[min_top - 1]] >= value) {
            min_top -= 1;
            const position = min_stack[min_top];
            const start = if (min_top > 0) min_stack[min_top - 1] + 1 else 0;
            addRange(1, 0, n - 1, start, position, permutation[position], segment_min[0..], lazy[0..]);
        }
        while (max_top > 0 and permutation[max_stack[max_top - 1]] <= value) {
            max_top -= 1;
            const position = max_stack[max_top];
            const start = if (max_top > 0) max_stack[max_top - 1] + 1 else 0;
            addRange(1, 0, n - 1, start, position, -permutation[position], segment_min[0..], lazy[0..]);
        }
        const start_min = if (min_top > 0) min_stack[min_top - 1] + 1 else 0;
        addRange(1, 0, n - 1, start_min, end, -value, segment_min[0..], lazy[0..]);
        min_stack[min_top] = end;
        min_top += 1;
        const start_max = if (max_top > 0) max_stack[max_top - 1] + 1 else 0;
        addRange(1, 0, n - 1, start_max, end, value, segment_min[0..], lazy[0..]);
        max_stack[max_top] = end;
        max_top += 1;

        const leftmost = firstZero(1, 0, n - 1, segment_min[0..]);
        var current = node_count;
        node_count += 1;
        node_left[current] = @intCast(end);
        node_right[current] = @intCast(end);
        while (node_top > 0 and node_left[node_stack[node_top - 1]] >= @as(i32, @intCast(leftmost))) {
            const top = node_stack[node_top - 1];
            if (node_combine[top] and connected(@intCast(node_last[top]), end, logs[0..], range_min[0..], range_max[0..])) {
                node_right[top] = @intCast(end);
                node_last[top] = node_left[current];
                node_top -= 1;
                current = node_stack[node_top];
            } else if (connected(@intCast(node_left[top]), end, logs[0..], range_min[0..], range_max[0..])) {
                const merged = node_count;
                node_count += 1;
                node_left[merged] = node_left[top];
                node_right[merged] = @intCast(end);
                node_combine[merged] = true;
                node_last[merged] = node_left[current];
                node_top -= 1;
                current = merged;
            } else {
                const merged = node_count;
                node_count += 1;
                node_left[merged] = -1;
                node_right[merged] = @intCast(end);
                node_top -= 1;
                while (node_top > 0 and !connected(@intCast(node_left[node_stack[node_top - 1]]), end,
                                                   logs[0..], range_min[0..], range_max[0..])) {
                    node_top -= 1;
                }
                if (node_top == 0) return -1;
                node_top -= 1;
                const base = node_stack[node_top];
                node_left[merged] = node_left[base];
                current = merged;
            }
        }
        node_stack[node_top] = current;
        node_top += 1;
        addRange(1, 0, n - 1, 0, end, -1, segment_min[0..], lazy[0..]);
    }

    for (1..node_count) |i| {
        const left = node_left[i];
        const right = node_right[i];
        var j = i;
        while (j > 0 and (node_left[j - 1] > left or
               (node_left[j - 1] == left and node_right[j - 1] > right))) {
            node_left[j] = node_left[j - 1];
            node_right[j] = node_right[j - 1];
            j -= 1;
        }
        node_left[j] = left;
        node_right[j] = right;
    }
    var checksum: i64 = 0;
    for (0..node_count) |i| {
        checksum += @as(i64, @intCast(i + 1))
            * ((@as(i64, node_left[i]) + 1) * @as(i64, @intCast(n + 1))
               + @as(i64, node_right[i]) + 1);
    }
    return checksum;
}
