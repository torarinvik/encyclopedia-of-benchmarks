/// Point updates and sum-monoid max_right boundary searches.
export fn segment_tree_max_right(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 55) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 16 or input[1] < 0 or input[1] > 12) return -1;
    const n: usize = @intCast(input[0]);
    const operations: usize = @intCast(input[1]);
    if (length != 2 + n + 3 * operations) return -1;

    var tree: [64]i64 = @splat(0);
    var size: usize = 1;
    while (size < n) : (size *= 2) {}
    for (0..n) |i| {
        const value = input[2 + i];
        if (value < 0 or value > 1000) return -1;
        tree[size + i] = value;
    }
    var node = size;
    while (node > 1) {
        node -= 1;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    var query_index: usize = 0;
    var result: i64 = 0;
    var cursor: usize = 2 + n;
    for (0..operations) |_| {
        const opcode = input[cursor];
        const first = input[cursor + 1];
        const second = input[cursor + 2];
        cursor += 3;
        if (opcode == 0) {
            if (first < 0 or first >= @as(i64, @intCast(n)) or second < 0 or second > 1000) return -1;
            node = size + @as(usize, @intCast(first));
            tree[node] = second;
            while (node > 1) {
                node /= 2;
                tree[node] = tree[2 * node] + tree[2 * node + 1];
            }
        } else if (opcode == 1) {
            if (first < 0 or first > @as(i64, @intCast(n)) or second < 0 or second > 16000) return -1;
            const left: usize = @intCast(first);
            var boundary = n;
            if (left < n) {
                var position = left + size;
                var accumulated: i64 = 0;
                var done = false;
                while (!done) {
                    while ((position & 1) == 0) position /= 2;
                    if (accumulated + tree[position] > second) {
                        while (position < size) {
                            position *= 2;
                            if (accumulated + tree[position] <= second) {
                                accumulated += tree[position];
                                position += 1;
                            }
                        }
                        boundary = @min(position - size, n);
                        done = true;
                    } else {
                        accumulated += tree[position];
                        position += 1;
                        if ((position & (position - 1)) == 0) done = true;
                    }
                }
            }
            result |= @as(i64, @intCast(boundary)) << @intCast(5 * query_index);
            query_index += 1;
        } else {
            return -1;
        }
    }
    return result;
}
