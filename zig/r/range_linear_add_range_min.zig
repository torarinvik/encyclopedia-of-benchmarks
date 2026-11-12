const MAX_LENGTH: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT: usize = 387;
const BLOCK_WIDTH: usize = 8;
const MAX_BLOCKS: usize = 8;
const CHECKSUM_OFFSET: i64 = 8_000_000;

const State = struct {
    data: [MAX_LENGTH]i64 = @splat(0),
    hull_x: [MAX_LENGTH]i64 = @splat(0),
    hull_y: [MAX_LENGTH]i64 = @splat(0),
    hull_count: [MAX_BLOCKS]usize = @splat(0),
    lazy_slope: [MAX_BLOCKS]i64 = @splat(0),
    lazy_intercept: [MAX_BLOCKS]i64 = @splat(0),
    n: usize = 0,

    fn blockEnd(self: *const State, block: usize) usize {
        return @min((block + 1) * BLOCK_WIDTH, self.n);
    }

    fn rebuild(self: *State, block: usize) void {
        const base = block * BLOCK_WIDTH;
        var size: usize = 0;
        for (base..self.blockEnd(block)) |x| {
            while (size >= 2) {
                const p = base + size - 2;
                const q = base + size - 1;
                const cross = (self.hull_x[q] - self.hull_x[p]) *
                    (self.data[x] - self.hull_y[p]) -
                    (self.hull_y[q] - self.hull_y[p]) *
                    (@as(i64, @intCast(x)) - self.hull_x[p]);
                if (cross > 0) break;
                size -= 1;
            }
            self.hull_x[base + size] = @intCast(x);
            self.hull_y[base + size] = self.data[x];
            size += 1;
        }
        self.hull_count[block] = size;
    }

    fn push(self: *State, block: usize) void {
        const start = block * BLOCK_WIDTH;
        for (start..self.blockEnd(block)) |i| {
            self.data[i] += self.lazy_slope[block] * @as(i64, @intCast(i)) + self.lazy_intercept[block];
        }
        self.lazy_slope[block] = 0;
        self.lazy_intercept[block] = 0;
    }

    fn blockMin(self: *const State, block: usize) i64 {
        const base = block * BLOCK_WIDTH;
        var low: usize = 0;
        var high = self.hull_count[block] - 1;
        while (low < high) {
            const middle = low + (high - low) / 2;
            const left = self.hull_y[base + middle] + self.lazy_slope[block] * self.hull_x[base + middle];
            const right = self.hull_y[base + middle + 1] + self.lazy_slope[block] * self.hull_x[base + middle + 1];
            if (left <= right) high = middle else low = middle + 1;
        }
        return self.hull_y[base + low] + self.lazy_slope[block] * self.hull_x[base + low]
            + self.lazy_intercept[block];
    }

    fn update(self: *State, left: usize, right: usize, slope: i64, intercept: i64) void {
        var position = left;
        while (position < right) {
            const block = position / BLOCK_WIDTH;
            const start = block * BLOCK_WIDTH;
            const finish = self.blockEnd(block);
            if (position == start and finish <= right) {
                self.lazy_slope[block] += slope;
                self.lazy_intercept[block] += intercept;
                position = finish;
            } else {
                self.push(block);
                const stop = @min(finish, right);
                for (position..stop) |i| self.data[i] += slope * @as(i64, @intCast(i)) + intercept;
                self.rebuild(block);
                position = stop;
            }
        }
    }

    fn query(self: *const State, left: usize, right: usize) i64 {
        var position = left;
        var minimum: i64 = 9223372036854775807;
        while (position < right) {
            const block = position / BLOCK_WIDTH;
            const start = block * BLOCK_WIDTH;
            const finish = self.blockEnd(block);
            if (position == start and finish <= right) {
                minimum = @min(minimum, self.blockMin(block));
                position = finish;
            } else {
                const stop = @min(finish, right);
                for (position..stop) |i| {
                    minimum = @min(minimum, self.data[i] + self.lazy_slope[block] * @as(i64, @intCast(i))
                                   + self.lazy_intercept[block]);
                }
                position = stop;
            }
        }
        return minimum;
    }
};

export fn range_linear_add_range_min_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_LENGTH)) or
        input[1] < 1 or input[1] > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    if (length < n + 2) return -1;
    var state = State{ .n = n };
    for (0..n) |i| {
        if (input[i + 2] < -1_000_000 or input[i + 2] > 1_000_000) return -1;
        state.data[i] = input[i + 2];
    }
    for (0..(n + BLOCK_WIDTH - 1) / BLOCK_WIDTH) |block| state.rebuild(block);
    var cursor = n + 2;
    var checksum: i64 = 0;
    for (0..q) |operation| {
        if (cursor >= length) return -1;
        const opcode = input[cursor];
        cursor += 1;
        if (opcode == 0) {
            if (cursor + 4 > length) return -1;
            const left = input[cursor];
            const right = input[cursor + 1];
            const slope = input[cursor + 2];
            const intercept = input[cursor + 3];
            cursor += 4;
            if (left < 0 or left >= right or right > @as(i64, @intCast(n)) or
                slope < -99 or slope > 99 or intercept < -100_000 or intercept > 100_000) return -1;
            state.update(@intCast(left), @intCast(right), slope, intercept);
        } else if (opcode == 1) {
            if (cursor + 2 > length) return -1;
            const left = input[cursor];
            const right = input[cursor + 1];
            cursor += 2;
            if (left < 0 or left >= right or right > @as(i64, @intCast(n))) return -1;
            checksum += @as(i64, @intCast(operation + 1)) *
                (state.query(@intCast(left), @intCast(right)) + CHECKSUM_OFFSET);
        } else return -1;
    }
    return if (cursor == length) checksum else -1;
}
