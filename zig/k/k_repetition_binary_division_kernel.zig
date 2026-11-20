const MAX_N: usize = 32;
const MAX_K: usize = 3;
const MAX_INPUT: usize = 35;
const MAX_PERIODS: usize = 17;
const BIT_WORDS: usize = 272;
const MAX_FACTORS: usize = 33;
const MAX_OUTPUT: usize = 91400;

const Search = struct {
    text: [MAX_N]i32,
    n: usize,
    budget: usize,
    starts: [MAX_FACTORS]usize,
    ends: [MAX_FACTORS]usize,
    factor_count: usize,
    seen: [BIT_WORDS]u64,
};

fn lp(text: *const [MAX_N]i32, lo: usize, hi: usize, center: usize,
      period: usize, allowed: usize) usize {
    const left = center - period;
    const limit = @min(hi - left, hi - center);
    var errors: usize = 0;
    for (0..limit) |j| {
        if (text[left + j] != text[center + j]) {
            errors += 1;
            if (errors > allowed) return j;
        }
    }
    return limit;
}

fn ls(text: *const [MAX_N]i32, lo: usize, center: usize,
      period: usize, allowed: usize) usize {
    const limit = @min(center - period - lo, center - lo);
    var errors: usize = 0;
    for (0..limit) |j| {
        if (text[center - period - 1 - j] != text[center - 1 - j]) {
            errors += 1;
            if (errors > allowed) return j;
        }
    }
    return limit;
}

fn mark(state: *Search, lo: usize, last_head: usize,
        local_start: usize, local_end: usize, period: usize) void {
    const start = lo + local_start;
    const end = lo + local_end;
    if (start <= lo or end >= state.n or end - start + 1 < 2 * period) return;
    if (start <= last_head + 1 and end + 1 >= last_head) return;
    const index = (start * MAX_N + end) * MAX_PERIODS + period;
    state.seen[index / 64] |= @as(u64, 1) << @intCast(index % 64);
}

fn atCenter(state: *Search, lo: usize, hi: usize, center: usize, last_head: usize) void {
    if (center <= lo or center + 1 >= hi) return;
    for (1..center - lo + 1) |period| {
        for (0..state.budget + 1) |k| {
            const forward = lp(&state.text, lo, hi, center, period, k);
            const backward = ls(&state.text, lo, center, period, state.budget - k);
            if (forward <= period and forward + backward >= period)
                mark(state, lo, last_head, center - period - backward - lo,
                     center + forward - 1 - lo, period);
        }
    }
    var reversed = [_]i32{0} ** MAX_N;
    const size = hi - lo;
    for (0..size) |i| reversed[i] = state.text[hi - 1 - i];
    const rc = size - 1 - (center - lo);
    for (1..rc + 1) |period| {
        for (0..state.budget + 1) |k| {
            const forward = lp(&reversed, 0, size, rc, period, k);
            const backward = ls(&reversed, 0, rc, period, state.budget - k);
            if (forward <= period and forward + backward >= period) {
                const rs = rc - period - backward;
                const re = rc + forward - 1;
                mark(state, lo, last_head, size - 1 - re, size - 1 - rs, period);
            }
        }
    }
}

fn divide(state: *Search, first: usize, last: usize) void {
    if (first >= last) return;
    const middle = first + (last - first) / 2;
    const lo = state.starts[first];
    const hi = state.ends[last];
    const center = state.ends[middle] - 1;
    const last_head = state.ends[last] - 1;
    atCenter(state, lo, hi, center, last_head);
    divide(state, first, middle);
    divide(state, middle + 1, last);
}

fn encodeI64(output: [*c]u8, offset: usize, value: u64) void {
    for (0..8) |byte| output[offset + byte] = @intCast((value >> @intCast(8 * byte)) & 255);
}

export fn k_repetition_binary_division_kernel(values: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 3 or length > MAX_INPUT) return -1;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))
        or values[1] < 0 or values[1] > @as(i64, @intCast(MAX_K))) return -1;
    const n: usize = @intCast(values[0]);
    const budget: usize = @intCast(values[1]);
    if (length != n + 2) return -1;

    var state = Search{
        .text = [_]i32{0} ** MAX_N,
        .n = n,
        .budget = budget,
        .starts = [_]usize{0} ** MAX_FACTORS,
        .ends = [_]usize{0} ** MAX_FACTORS,
        .factor_count = 0,
        .seen = [_]u64{0} ** BIT_WORDS,
    };
    for (0..n) |i| {
        if (values[i + 2] < 0 or values[i + 2] > 4) return -1;
        state.text[i] = @intCast(values[i + 2]);
    }
    for (0..n - 1) |i| if (state.text[i] == state.text[n - 1]) return -1;

    var pos: usize = 0;
    while (pos < n) {
        var best: usize = 0;
        for (0..pos) |earlier| {
            var matched: usize = 0;
            while (pos + matched < n and earlier + matched < n
                   and state.text[earlier + matched] == state.text[pos + matched]) : (matched += 1) {}
            best = @max(best, matched);
        }
        const end = @min(n, pos + best + 1);
        state.starts[state.factor_count] = pos;
        state.ends[state.factor_count] = end;
        state.factor_count += 1;
        pos = end;
    }
    const block = budget + 2;
    var first: usize = 0;
    while (first < state.factor_count) : (first += block)
        divide(&state, first, @min(state.factor_count, first + block) - 1);

    var records: usize = 0;
    for (0..n) |start| {
        for (2..n - start + 1) |size| {
            const end = start + size - 1;
            for (1..size / 2 + 1) |period| {
                const index = (start * MAX_N + end) * MAX_PERIODS + period;
                if (state.seen[index / 64] & (@as(u64, 1) << @intCast(index % 64)) != 0) records += 1;
            }
        }
    }
    const written = 8 + records * 32;
    if (written > MAX_OUTPUT) return -1;
    if (output == null or capacity < written) return -2;
    encodeI64(output, 0, records);
    var offset: usize = 8;
    for (0..n) |start| {
        for (2..n - start + 1) |size| {
            const end = start + size - 1;
            for (1..size / 2 + 1) |period| {
                const index = (start * MAX_N + end) * MAX_PERIODS + period;
                if (state.seen[index / 64] & (@as(u64, 1) << @intCast(index % 64)) == 0) continue;
                var mismatches: usize = 0;
                for (start..end - period + 1) |i| if (state.text[i] != state.text[i + period]) { mismatches += 1; };
                encodeI64(output, offset, start); offset += 8;
                encodeI64(output, offset, size); offset += 8;
                encodeI64(output, offset, period); offset += 8;
                encodeI64(output, offset, mismatches); offset += 8;
            }
        }
    }
    return @intCast(written);
}
