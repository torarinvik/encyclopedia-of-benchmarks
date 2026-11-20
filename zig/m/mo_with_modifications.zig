const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_INPUT_LENGTH: usize = 258;

const Query = struct {
    left: usize,
    right: usize,
    time: usize,
    ordinal: usize,
};

const Change = struct {
    position: usize,
    before_value: usize,
    after_value: usize,
};

const Window = struct {
    values: [MAX_N]usize = [_]usize{0} ** MAX_N,
    frequencies: [16]usize = [_]usize{0} ** 16,
    distinct_count: usize = 0,
    left: i32 = 0,
    right: i32 = -1,

    fn add(self: *Window, position: usize) void {
        const value = self.values[position];
        if (self.frequencies[value] == 0) self.distinct_count += 1;
        self.frequencies[value] += 1;
    }
    fn remove(self: *Window, position: usize) void {
        const value = self.values[position];
        self.frequencies[value] -= 1;
        if (self.frequencies[value] == 0) self.distinct_count -= 1;
    }
    fn replace(self: *Window, position: usize, new_value: usize) void {
        const active = @as(i32, @intCast(position)) >= self.left and @as(i32, @intCast(position)) <= self.right;
        if (active) self.remove(position);
        self.values[position] = new_value;
        if (active) self.add(position);
    }
};

fn queryBefore(a: Query, b: Query, block_size: usize) bool {
    const left_block_a = a.left / block_size;
    const left_block_b = b.left / block_size;
    if (left_block_a != left_block_b) return left_block_a < left_block_b;
    const right_block_a = a.right / block_size;
    const right_block_b = b.right / block_size;
    if (right_block_a != right_block_b) return right_block_a < right_block_b;
    if (a.time != b.time) return a.time < b.time;
    return a.ordinal < b.ordinal;
}

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const n64 = input[0];
    const q64 = input[1];
    if (n64 < 1 or n64 > @as(i64, MAX_N) or q64 < 0 or q64 > @as(i64, MAX_Q)) return null;
    const n: usize = @intCast(n64);
    const q: usize = @intCast(q64);
    if (input.len != 2 + n + 3 * q) return null;

    var initial: [MAX_N]usize = [_]usize{0} ** MAX_N;
    for (0..n) |i| {
        if (input[2 + i] < 0 or input[2 + i] > 15) return null;
        initial[i] = @intCast(input[2 + i]);
    }
    const operation_offset = 2 + n;
    for (0..q) |i| {
        const op = input[operation_offset + 3 * i];
        const first = input[operation_offset + 3 * i + 1];
        const second = input[operation_offset + 3 * i + 2];
        if (op == 0) {
            if (first < 0 or first >= n64 or second < 0 or second > 15) return null;
        } else if (op == 1) {
            if (first < 0 or second < first or second >= n64) return null;
        } else return null;
    }

    var parse_state = initial;
    var changes: [MAX_Q]Change = undefined;
    var queries: [MAX_Q]Query = undefined;
    var change_count: usize = 0;
    var query_count: usize = 0;
    for (0..q) |i| {
        const op = input[operation_offset + 3 * i];
        const first: usize = @intCast(input[operation_offset + 3 * i + 1]);
        const second: usize = @intCast(input[operation_offset + 3 * i + 2]);
        if (op == 0) {
            changes[change_count] = .{ .position = first, .before_value = parse_state[first], .after_value = second };
            parse_state[first] = second;
            change_count += 1;
        } else {
            queries[query_count] = .{ .left = first, .right = second, .time = change_count, .ordinal = query_count };
            query_count += 1;
        }
    }

    var block_size: usize = 1;
    while ((block_size + 1) * (block_size + 1) * (block_size + 1) <= n * n) block_size += 1;
    var i: usize = 1;
    while (i < query_count) : (i += 1) {
        const current = queries[i];
        var position = i;
        while (position > 0 and queryBefore(current, queries[position - 1], block_size)) {
            queries[position] = queries[position - 1];
            position -= 1;
        }
        queries[position] = current;
    }

    var window = Window{ .values = initial };
    var current_time: usize = 0;
    var answers: [MAX_Q]usize = [_]usize{0} ** MAX_Q;
    for (0..query_count) |sorted| {
        const query = queries[sorted];
        while (current_time < query.time) {
            const change = changes[current_time];
            window.replace(change.position, change.after_value);
            current_time += 1;
        }
        while (current_time > query.time) {
            current_time -= 1;
            const change = changes[current_time];
            window.replace(change.position, change.before_value);
        }
        while (window.left > @as(i32, @intCast(query.left))) {
            window.left -= 1;
            window.add(@intCast(window.left));
        }
        while (window.right < @as(i32, @intCast(query.right))) {
            window.right += 1;
            window.add(@intCast(window.right));
        }
        while (window.left < @as(i32, @intCast(query.left))) {
            window.remove(@intCast(window.left));
            window.left += 1;
        }
        while (window.right > @as(i32, @intCast(query.right))) {
            window.remove(@intCast(window.right));
            window.right -= 1;
        }
        answers[query.ordinal] = window.distinct_count;
    }

    var checksum: i64 = 0;
    for (0..query_count) |ordinal| checksum += (@as(i64, @intCast(ordinal)) + 1) * (@as(i64, @intCast(answers[ordinal])) + 1);
    return checksum;
}

export fn mo_with_modifications(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
