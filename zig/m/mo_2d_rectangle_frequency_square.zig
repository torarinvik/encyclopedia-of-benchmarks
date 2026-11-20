const MAX_N: usize = 8;
const MAX_Q: usize = 32;
const MAX_CELLS: usize = 64;
const MAX_INPUT: usize = 194;
const MAX_PARSEABLE: usize = 195;

const RectQuery = struct {
    top: usize,
    left: usize,
    bottom: usize,
    right: usize,
    ordinal: usize,
};

const FrequencyState = struct {
    counts: [8]i64 = @splat(0),
    square_sum: i64 = 0,

    fn add(self: *FrequencyState, value: usize) void {
        const old = self.counts[value];
        self.square_sum += 2 * old + 1;
        self.counts[value] = old + 1;
    }

    fn remove(self: *FrequencyState, value: usize) void {
        const old = self.counts[value];
        self.square_sum += 1 - 2 * old;
        self.counts[value] = old - 1;
    }
};

fn queryBefore(a: RectQuery, b: RectQuery, block_size: usize) bool {
    const a_keys = [_]usize{ a.top / block_size, a.left / block_size, a.bottom / block_size, a.right / block_size,
        a.top, a.left, a.bottom, a.right, a.ordinal };
    const b_keys = [_]usize{ b.top / block_size, b.left / block_size, b.bottom / block_size, b.right / block_size,
        b.top, b.left, b.bottom, b.right, b.ordinal };
    for (0..a_keys.len) |index| {
        if (a_keys[index] != b_keys[index]) return a_keys[index] < b_keys[index];
    }
    return false;
}

export fn mo_2d_rectangle_frequency_square(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_PARSEABLE) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or q_value < 0 or q_value > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 2 + n * n + 4 * q or length > MAX_INPUT) return -1;

    var matrix: [MAX_CELLS]usize = @splat(0);
    for (0..n * n) |cell| {
        const value = input[2 + cell];
        if (value < 0 or value > 7) return -1;
        matrix[cell] = @intCast(value);
    }

    var queries: [MAX_Q]RectQuery = undefined;
    var cursor: usize = 2 + n * n;
    for (0..q) |query_index| {
        const top_value = input[cursor];
        const left_value = input[cursor + 1];
        const bottom_value = input[cursor + 2];
        const right_value = input[cursor + 3];
        if (top_value < 0 or top_value >= n_value or bottom_value < top_value or bottom_value >= n_value) return -1;
        if (left_value < 0 or left_value >= n_value or right_value < left_value or right_value >= n_value) return -1;
        queries[query_index] = .{
            .top = @intCast(top_value),
            .left = @intCast(left_value),
            .bottom = @intCast(bottom_value),
            .right = @intCast(right_value),
            .ordinal = query_index,
        };
        cursor += 4;
    }
    if (q == 0) return 0;

    var block_size: usize = 1;
    const n_fourth = n * n * n * n;
    while (block_size < n) {
        const candidate = block_size + 1;
        if (q * candidate * candidate * candidate * candidate <= n_fourth) block_size = candidate else break;
    }
    var query_index: usize = 1;
    while (query_index < q) : (query_index += 1) {
        const item = queries[query_index];
        var position = query_index;
        while (position > 0 and queryBefore(item, queries[position - 1], block_size)) {
            queries[position] = queries[position - 1];
            position -= 1;
        }
        queries[position] = item;
    }

    var answers: [MAX_Q]i64 = @splat(0);
    var state = FrequencyState{};
    const first = queries[0];
    var current_top = first.top;
    var current_bottom = first.bottom;
    var current_left = first.left;
    var current_right = first.right;
    for (current_top..current_bottom + 1) |row| {
        for (current_left..current_right + 1) |column| state.add(matrix[row * n + column]);
    }
    answers[first.ordinal] = state.square_sum;

    for (1..q) |sorted_position| {
        const query = queries[sorted_position];
        while (current_top > query.top) {
            current_top -= 1;
            for (current_left..current_right + 1) |column| state.add(matrix[current_top * n + column]);
        }
        while (current_bottom < query.bottom) {
            current_bottom += 1;
            for (current_left..current_right + 1) |column| state.add(matrix[current_bottom * n + column]);
        }
        while (current_left > query.left) {
            current_left -= 1;
            for (current_top..current_bottom + 1) |row| state.add(matrix[row * n + current_left]);
        }
        while (current_right < query.right) {
            current_right += 1;
            for (current_top..current_bottom + 1) |row| state.add(matrix[row * n + current_right]);
        }
        while (current_top < query.top) {
            for (current_left..current_right + 1) |column| state.remove(matrix[current_top * n + column]);
            current_top += 1;
        }
        while (current_bottom > query.bottom) {
            for (current_left..current_right + 1) |column| state.remove(matrix[current_bottom * n + column]);
            current_bottom -= 1;
        }
        while (current_left < query.left) {
            for (current_top..current_bottom + 1) |row| state.remove(matrix[row * n + current_left]);
            current_left += 1;
        }
        while (current_right > query.right) {
            for (current_top..current_bottom + 1) |row| state.remove(matrix[row * n + current_right]);
            current_right -= 1;
        }
        answers[query.ordinal] = state.square_sum;
    }

    var checksum: i64 = 0;
    for (0..q) |index| checksum += @as(i64, @intCast(index + 1)) * answers[index];
    return checksum;
}
