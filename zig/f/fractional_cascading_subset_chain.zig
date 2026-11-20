const MAX_M: usize = 8;
const MAX_Q: usize = 8;
const MAX_N: usize = 16;
const MAX_LENGTH: usize = 147;
const NO_SUCCESSOR: i64 = 34;

export fn fractional_cascading_subset_chain(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_LENGTH) return -1;
    if (input[0] < 2 or input[0] > 8 or input[1] < 1 or input[1] > 8) return -1;
    const m: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    var catalogs: [MAX_M * MAX_N]i64 = @splat(0);
    var sizes: [MAX_M]usize = @splat(0);
    var queries: [MAX_Q]i64 = @splat(0);
    var cursor: usize = 2;
    for (0..m) |i| {
        if (cursor >= length or input[cursor] < 1 or input[cursor] > 16) return -1;
        const n: usize = @intCast(input[cursor]);
        cursor += 1;
        if (cursor + n > length) return -1;
        sizes[i] = n;
        for (0..n) |j| {
            const key = input[cursor];
            cursor += 1;
            if (key < -16 or key > 16 or (j > 0 and catalogs[i * MAX_N + j - 1] >= key)) return -1;
            catalogs[i * MAX_N + j] = key;
        }
        if (i > 0) {
            var parent_pos: usize = 0;
            var child_pos: usize = 0;
            while (parent_pos < sizes[i - 1] and child_pos < n) {
                const parent_key = catalogs[(i - 1) * MAX_N + parent_pos];
                const child_key = catalogs[i * MAX_N + child_pos];
                if (parent_key < child_key) {
                    parent_pos += 1;
                } else if (parent_key == child_key) {
                    parent_pos += 1;
                    child_pos += 1;
                } else {
                    return -1;
                }
            }
            if (child_pos != n) return -1;
        }
    }
    if (cursor + q != length) return -1;
    for (0..q) |i| {
        queries[i] = input[cursor + i];
        if (queries[i] < -17 or queries[i] > 17) return -1;
    }

    var bridges: [(MAX_M - 1) * (MAX_N + 1)]usize = @splat(0);
    for (0..m - 1) |i| {
        var child: usize = 0;
        for (0..sizes[i]) |slot| {
            while (child < sizes[i + 1] and catalogs[(i + 1) * MAX_N + child] < catalogs[i * MAX_N + slot]) : (child += 1) {}
            bridges[i * (MAX_N + 1) + slot] = child;
        }
        bridges[i * (MAX_N + 1) + sizes[i]] = sizes[i + 1];
    }

    var checksum: i64 = 0;
    for (0..q) |qi| {
        var low: usize = 0;
        var high = sizes[0];
        while (low < high) {
            const middle = (low + high) / 2;
            if (catalogs[middle] < queries[qi]) low = middle + 1 else high = middle;
        }
        var slot = low;
        for (0..m) |ci| {
            const code = if (slot < sizes[ci]) catalogs[ci * MAX_N + slot] + 17 else NO_SUCCESSOR;
            checksum += @as(i64, @intCast(qi + 1)) * @as(i64, @intCast(ci + 1)) * code;
            if (ci + 1 < m) slot = bridges[ci * (MAX_N + 1) + slot];
        }
    }
    return checksum;
}
