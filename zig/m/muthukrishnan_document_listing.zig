const MAX_N: usize = 32;
const MAX_DOCS: usize = 8;
const MAX_Q: usize = 16;
const MAX_INPUT: usize = 68;
const MAX_OUTPUT: usize = 144;
const LEVELS: usize = 6;

const State = struct {
    da: [MAX_N]i64 = [_]i64{0} ** MAX_N,
    previous: [MAX_N]i64 = [_]i64{0} ** MAX_N,
    logs: [MAX_N + 1]u8 = [_]u8{0} ** (MAX_N + 1),
    table: [LEVELS * MAX_N]i32 = [_]i32{0} ** (LEVELS * MAX_N),
    found_ranks: [MAX_DOCS]usize = [_]usize{0} ** MAX_DOCS,
    found_docs: [MAX_DOCS]u8 = [_]u8{0} ** MAX_DOCS,
    found_count: usize = 0,
    staged: [MAX_OUTPUT]u8 = [_]u8{0} ** MAX_OUTPUT,
    written: usize = 0,
};

fn rangeMin(state: *const State, lo: usize, hi: usize) usize {
    const level: usize = state.logs[hi - lo + 1];
    const width: usize = @as(usize, 1) << @intCast(level);
    const left: usize = @intCast(state.table[level * MAX_N + lo]);
    const right: usize = @intCast(state.table[level * MAX_N + hi - width + 1]);
    if (state.previous[left] < state.previous[right] or
        (state.previous[left] == state.previous[right] and left < right)) return left;
    return right;
}

fn report(state: *State, lo: usize, hi: usize, query_lo: usize, count: *usize) void {
    if (lo > hi) return;
    const index = rangeMin(state, lo, hi);
    if (state.previous[index] >= @as(i64, @intCast(query_lo))) return;
    state.found_ranks[state.found_count] = index;
    state.found_docs[state.found_count] = @intCast(state.da[index]);
    state.found_count += 1;
    count.* += 1;
    if (index > lo) report(state, lo, index - 1, query_lo, count);
    if (index < hi) report(state, index + 1, hi, query_lo, count);
}

export fn muthukrishnan_document_listing(input: ?[*]const i64, length: usize,
        output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 3 or length > MAX_INPUT) return -1;
    const n_value = values[0];
    const docs_value = values[1];
    const q_value = values[2];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or
        docs_value < 1 or docs_value > @as(i64, @intCast(MAX_DOCS)) or
        q_value < 1 or q_value > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 3 + n + 2 * q) return -1;

    var state = State{};
    var last: [MAX_DOCS]i64 = [_]i64{-1} ** MAX_DOCS;
    for (0..n) |i| {
        const document = values[3 + i];
        if (document < 0 or document >= docs_value) return -1;
        state.da[i] = document;
        state.previous[i] = last[@intCast(document)];
        last[@intCast(document)] = @intCast(i);
    }
    for (0..q) |query| {
        const lo = values[3 + n + 2 * query];
        const hi = values[4 + n + 2 * query];
        if (lo < 0 or hi < lo or hi >= n_value) return -1;
    }

    for (2..n + 1) |size| state.logs[size] = state.logs[size / 2] + 1;
    for (0..n) |i| state.table[i] = @intCast(i);
    const level_count: usize = @as(usize, state.logs[n]) + 1;
    for (1..level_count) |level| {
        const width = @as(usize, 1) << @intCast(level);
        const half = width / 2;
        for (0..(n - width + 1)) |start| {
            const left: usize = @intCast(state.table[(level - 1) * MAX_N + start]);
            const right: usize = @intCast(state.table[(level - 1) * MAX_N + start + half]);
            state.table[level * MAX_N + start] = if (state.previous[left] < state.previous[right] or
                (state.previous[left] == state.previous[right] and left < right)) @intCast(left) else @intCast(right);
        }
    }

    for (0..q) |query| {
        const lo: usize = @intCast(values[3 + n + 2 * query]);
        const hi: usize = @intCast(values[4 + n + 2 * query]);
        const count_at = state.written;
        state.written += 1;
        state.found_count = 0;
        var count: usize = 0;
        report(&state, lo, hi, lo, &count);
        for (1..state.found_count) |i| {
            const rank = state.found_ranks[i];
            const document = state.found_docs[i];
            var j = i;
            while (j > 0 and state.found_ranks[j - 1] > rank) : (j -= 1) {
                state.found_ranks[j] = state.found_ranks[j - 1];
                state.found_docs[j] = state.found_docs[j - 1];
            }
            state.found_ranks[j] = rank;
            state.found_docs[j] = document;
        }
        state.staged[count_at] = @intCast(count);
        for (0..state.found_count) |i| {
            state.staged[state.written] = state.found_docs[i];
            state.written += 1;
        }
    }
    if (state.written > MAX_OUTPUT) return -1;
    const out = output orelse return -2;
    if (capacity < state.written) return -2;
    for (0..state.written) |i| out[i] = state.staged[i];
    return @intCast(state.written);
}
