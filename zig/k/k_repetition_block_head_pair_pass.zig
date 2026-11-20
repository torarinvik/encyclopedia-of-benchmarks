const MAX_N: usize = 24;
const MAX_K: usize = 3;
const MAX_INPUT: usize = 27;
const MAX_CONTEXT: usize = 48;
const MAX_FACTORS: usize = 25;
const MAX_PERIODS: usize = 13;
const BIT_WORDS: usize = 117;
const MAX_OUTPUT: usize = 39112;

const State = struct {
    text: [MAX_N]i32,
    starts: [MAX_FACTORS]usize,
    ends: [MAX_FACTORS]usize,
    seen: [BIT_WORDS]u64,
    n: usize,
    budget: usize,
    factor_count: usize,
};

fn right(w: *const [MAX_CONTEXT]i32, size: usize, center: usize, period: usize, allowed: usize) usize {
    const left = center - period;
    const limit = @min(size - left, size - center);
    var errors: usize = 0;
    for (0..limit) |d| {
        if (w[left + d] != w[center + d]) {
            errors += 1;
            if (errors > allowed) return d;
        }
    }
    return limit;
}

fn left(w: *const [MAX_CONTEXT]i32, center: usize, period: usize, allowed: usize) usize {
    const limit = center - period;
    var errors: usize = 0;
    for (0..limit) |d| {
        if (w[center - period - 1 - d] != w[center - 1 - d]) {
            errors += 1;
            if (errors > allowed) return d;
        }
    }
    return limit;
}

fn mark(s: *State, base: usize, size: usize, center: usize, next: usize,
        lo: usize, hi: usize, period: usize) void {
    if (hi >= size or hi - lo + 1 < 2 * period) return;
    if (lo > center + 1 or hi + 1 < center) return;
    if (lo <= next + 1 and hi + 1 >= next) return;
    const start = base + lo;
    const finish = base + hi;
    if (finish >= s.n) return;
    const index = (start * MAX_N + finish) * MAX_PERIODS + period;
    s.seen[index / 64] |= @as(u64, 1) << @intCast(index % 64);
}

fn atHead(s: *State, w: *const [MAX_CONTEXT]i32, size: usize, base: usize,
          center: usize, next: usize) void {
    if (center == 0 or center + 1 >= size) return;
    for (1..center + 1) |period| {
        for (0..s.budget + 1) |split| {
            const f = right(w, size, center, period, split);
            const b = left(w, center, period, s.budget - split);
            if (f <= period and f + b >= period)
                mark(s, base, size, center, next, center - period - b, center + f - 1, period);
        }
    }
    var reversed = [_]i32{0} ** MAX_CONTEXT;
    for (0..size) |i| reversed[i] = w[size - 1 - i];
    const rc = size - 1 - center;
    for (1..rc + 1) |period| {
        for (0..s.budget + 1) |split| {
            const f = right(&reversed, size, rc, period, split);
            const b = left(&reversed, rc, period, s.budget - split);
            if (f <= period and f + b >= period) {
                const rs = rc - period - b;
                const re = rc + f - 1;
                mark(s, base, size, center, next, size - 1 - re, size - 1 - rs, period);
            }
        }
    }
}

fn factorize(s: *State) void {
    var pos: usize = 0;
    while (pos < s.n) {
        var best: usize = 0;
        for (0..pos) |earlier| {
            var matched: usize = 0;
            while (pos + matched < s.n and earlier + matched < s.n and
                   s.text[earlier + matched] == s.text[pos + matched]) : (matched += 1) {}
            best = @max(best, matched);
        }
        s.starts[s.factor_count] = pos;
        const finish = @min(s.n, pos + best + 1);
        s.ends[s.factor_count] = finish;
        s.factor_count += 1;
        pos = finish;
    }
}

fn runHeads(s: *State) void {
    const block = s.budget + 2;
    const blocks = (s.factor_count + block - 1) / block;
    if (blocks < 2) return;
    for (0..blocks - 1) |bi| {
        const first = bi * block;
        const first_end = @min(s.factor_count, first + block);
        const second_end = @min(s.factor_count, first_end + block);
        const head = s.ends[first_end - 1] - 1;
        const next = s.ends[second_end - 1] - 1;
        const pair_start = s.starts[first];
        const pair_end = s.ends[second_end - 1];
        const span = pair_end - pair_start;
        const base = if (pair_start > span) pair_start - span else 0;
        const size = pair_end - base;
        var local = [_]i32{0} ** MAX_CONTEXT;
        for (0..size) |i| local[i] = s.text[base + i];
        atHead(s, &local, size, base, head - base, next - base);
    }
}

fn marked(s: *const State, start: usize, finish: usize, period: usize) bool {
    const index = (start * MAX_N + finish) * MAX_PERIODS + period;
    return s.seen[index / 64] & (@as(u64, 1) << @intCast(index % 64)) != 0;
}

fn put(output: [*c]u8, offset: usize, value: u64) void {
    for (0..8) |b| output[offset + b] = @intCast((value >> @intCast(8 * b)) & 255);
}

export fn k_repetition_block_head_pair_pass(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 3 or length > MAX_INPUT) return -1;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N)) or
        values[1] < 0 or values[1] > @as(i64, @intCast(MAX_K))) return -1;
    const n: usize = @intCast(values[0]);
    const budget: usize = @intCast(values[1]);
    if (length != n + 2) return -1;
    var s = State{ .text = [_]i32{0} ** MAX_N, .starts = [_]usize{0} ** MAX_FACTORS,
        .ends = [_]usize{0} ** MAX_FACTORS, .seen = [_]u64{0} ** BIT_WORDS,
        .n = n, .budget = budget, .factor_count = 0 };
    for (0..n) |i| {
        if (values[i + 2] < 0 or values[i + 2] > 4) return -1;
        s.text[i] = @intCast(values[i + 2]);
    }
    for (0..n - 1) |i| if (s.text[i] == s.text[n - 1]) return -1;
    factorize(&s);
    runHeads(&s);
    var count: usize = 0;
    for (0..n) |start| {
        for (2..n - start + 1) |len| {
            const finish = start + len - 1;
            for (1..len / 2 + 1) |period| if (marked(&s, start, finish, period)) { count += 1; };
        }
    }
    const bytes = 8 + count * 32;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null or capacity < bytes) return -2;
    put(output, 0, count);
    var offset: usize = 8;
    for (0..n) |start| {
        for (2..n - start + 1) |len| {
            const finish = start + len - 1;
            for (1..len / 2 + 1) |period| {
                if (!marked(&s, start, finish, period)) continue;
                var errors: usize = 0;
                for (start..finish - period + 1) |i| if (s.text[i] != s.text[i + period]) { errors += 1; };
                put(output, offset, start); offset += 8;
                put(output, offset, len); offset += 8;
                put(output, offset, period); offset += 8;
                put(output, offset, errors); offset += 8;
            }
        }
    }
    return @intCast(bytes);
}
