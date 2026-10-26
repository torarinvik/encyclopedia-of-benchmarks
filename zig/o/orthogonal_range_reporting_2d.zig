const MAX_POINTS: usize = 8;
const MAX_QUERIES: usize = 8;
const MAX_INPUT_LENGTH: usize = 50;
const BASE: usize = 8;
const MAX_OUTPUT_WORDS: usize = 73;

fn lowerX(order: [*]const usize, n: usize, xs: [*]const i64, bound: i64) usize {
    var low: usize = 0;
    var high = n;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (xs[order[middle]] < bound) low = middle + 1 else high = middle;
    }
    return low;
}

fn upperX(order: [*]const usize, n: usize, xs: [*]const i64, bound: i64) usize {
    var low: usize = 0;
    var high = n;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (xs[order[middle]] <= bound) low = middle + 1 else high = middle;
    }
    return low;
}

fn reportNode(node: usize, tree_ids: [*]const usize, tree_size: [*]const usize,
    ys: [*]const i64, y_low: i64, y_high: i64, hits: [*]usize, offset: usize) usize {
    var low: usize = 0;
    var high = tree_size[node];
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (ys[tree_ids[node * MAX_POINTS + middle]] < y_low) low = middle + 1 else high = middle;
    }
    const first = low;
    high = tree_size[node];
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (ys[tree_ids[node * MAX_POINTS + middle]] <= y_high) low = middle + 1 else high = middle;
    }
    for (first..low) |index| hits[offset + index - first] = tree_ids[node * MAX_POINTS + index];
    return low - first;
}

fn sortIds(ids: [*]usize, count: usize) void {
    for (1..count) |index| {
        const item = ids[index];
        var position = index;
        while (position > 0 and ids[position - 1] > item) {
            ids[position] = ids[position - 1];
            position -= 1;
        }
        ids[position] = item;
    }
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn orthogonal_range_reporting_2d(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > 8 or values[1] < 1 or values[1] > 8) return -1;
    const n: usize = @intCast(values[0]);
    const q: usize = @intCast(values[1]);
    if (length != 2 + 2 * n + 4 * q) return -1;

    var xs: [MAX_POINTS]i64 = [_]i64{0} ** MAX_POINTS;
    var ys: [MAX_POINTS]i64 = [_]i64{0} ** MAX_POINTS;
    for (0..n) |point| {
        xs[point] = values[2 + 2 * point];
        ys[point] = values[3 + 2 * point];
        if (xs[point] < 0 or xs[point] > 15 or ys[point] < 0 or ys[point] > 15) return -1;
        for (0..point) |earlier| {
            if (xs[earlier] == xs[point] and ys[earlier] == ys[point]) return -1;
        }
    }
    var queries: [MAX_QUERIES][4]i64 = [_][4]i64{[_]i64{0} ** 4} ** MAX_QUERIES;
    const query_start = 2 + 2 * n;
    for (0..q) |query| {
        for (0..4) |item| queries[query][item] = values[query_start + 4 * query + item];
        if (queries[query][0] < 0 or queries[query][0] > queries[query][1] or queries[query][1] > 15 or
            queries[query][2] < 0 or queries[query][2] > queries[query][3] or queries[query][3] > 15) return -1;
    }

    var order: [MAX_POINTS]usize = [_]usize{0} ** MAX_POINTS;
    for (0..n) |point| order[point] = point;
    for (1..n) |index| {
        const item = order[index];
        var position = index;
        while (position > 0) {
            const previous = order[position - 1];
            const before = xs[item] < xs[previous] or
                (xs[item] == xs[previous] and (ys[item] < ys[previous] or
                 (ys[item] == ys[previous] and item < previous)));
            if (!before) break;
            order[position] = previous;
            position -= 1;
        }
        order[position] = item;
    }

    var tree_ids: [2 * BASE][MAX_POINTS]usize = [_][MAX_POINTS]usize{[_]usize{0} ** MAX_POINTS} ** (2 * BASE);
    var tree_size: [2 * BASE]usize = [_]usize{0} ** (2 * BASE);
    for (0..n) |rank| {
        tree_ids[BASE + rank][0] = order[rank];
        tree_size[BASE + rank] = 1;
    }
    var node: usize = BASE - 1;
    while (node > 0) : (node -= 1) {
        var left: usize = 0;
        var right: usize = 0;
        const left_node = node * 2;
        const right_node = node * 2 + 1;
        while (left < tree_size[left_node] or right < tree_size[right_node]) {
            var take_left = right >= tree_size[right_node];
            if (!take_left and left < tree_size[left_node]) {
                const left_id = tree_ids[left_node][left];
                const right_id = tree_ids[right_node][right];
                take_left = ys[left_id] < ys[right_id] or (ys[left_id] == ys[right_id] and left_id < right_id);
            }
            var chosen: usize = 0;
            if (take_left) {
                chosen = tree_ids[left_node][left];
                left += 1;
            } else {
                chosen = tree_ids[right_node][right];
                right += 1;
            }
            tree_ids[node][tree_size[node]] = chosen;
            tree_size[node] += 1;
        }
    }

    var words: [MAX_OUTPUT_WORDS]i64 = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var cursor: usize = 0;
    words[cursor] = @intCast(q);
    cursor += 1;
    for (0..q) |query| {
        var left = lowerX(&order[0], n, &xs[0], queries[query][0]) + BASE;
        var right = upperX(&order[0], n, &xs[0], queries[query][1]) + BASE;
        var hits: [MAX_POINTS]usize = [_]usize{0} ** MAX_POINTS;
        var hit_count: usize = 0;
        while (left < right) {
            if ((left & 1) != 0) {
                hit_count += reportNode(left, &tree_ids[0][0], &tree_size[0], &ys[0],
                    queries[query][2], queries[query][3], &hits[0], hit_count);
                left += 1;
            }
            if ((right & 1) != 0) {
                right -= 1;
                hit_count += reportNode(right, &tree_ids[0][0], &tree_size[0], &ys[0],
                    queries[query][2], queries[query][3], &hits[0], hit_count);
            }
            left /= 2;
            right /= 2;
        }
        sortIds(&hits[0], hit_count);
        words[cursor] = @intCast(hit_count);
        cursor += 1;
        for (0..hit_count) |index| {
            words[cursor] = @intCast(hits[index]);
            cursor += 1;
        }
    }
    const output_bytes = 8 * cursor;
    if (output == null or capacity < output_bytes) return -2;
    const out = output.?;
    for (0..cursor) |word| storeI64Le(out, word * 8, words[word]);
    return @intCast(output_bytes);
}
