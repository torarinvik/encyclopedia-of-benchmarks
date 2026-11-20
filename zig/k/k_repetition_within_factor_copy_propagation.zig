const N: usize = 16;
const K: usize = 3;
const MAX_INPUT: usize = 1557;
const MAX_RECORDS: usize = 372;
const PERIODS: usize = 9;
const BIT_WORDS: usize = 39;
const MAX_OUTPUT: usize = 11912;

const Record = struct { start: i32, finish: i32, period: i32, errors: i32 };
const State = struct {
    word: [N]i32 = [_]i32{0} ** N,
    starts: [N]i32 = [_]i32{0} ** N,
    ends: [N]i32 = [_]i32{0} ** N,
    copies: [N]i32 = [_]i32{0} ** N,
    records: [MAX_RECORDS]Record = [_]Record{.{ .start = 0, .finish = 0, .period = 0, .errors = 0 }} ** MAX_RECORDS,
    known: [BIT_WORDS]u64 = [_]u64{0} ** BIT_WORDS,
    generated: [BIT_WORDS]u64 = [_]u64{0} ** BIT_WORDS,
    n: usize = 0,
    budget: usize = 0,
    factor_count: usize = 0,
    record_count: usize = 0,
};

fn bitIndex(start: usize, finish: usize, period: usize) usize {
    return (start * (N + 1) + finish) * PERIODS + period;
}

fn marked(bits: *const [BIT_WORDS]u64, bit: usize) bool {
    return bits[bit / 64] & (@as(u64, 1) << @intCast(bit % 64)) != 0;
}

fn lce(s: *const State, left: usize, right: usize) usize {
    var length: usize = 0;
    while (left + length < s.n and right + length < s.n and s.word[left + length] == s.word[right + length]) : (length += 1) {}
    return length;
}

fn less(a: Record, b: Record) bool {
    if (a.start != b.start) return a.start < b.start;
    if (a.finish != b.finish) return a.finish < b.finish;
    if (a.period != b.period) return a.period < b.period;
    return a.errors < b.errors;
}

fn addRecord(s: *State, record: Record, is_generated: bool) void {
    const bit = bitIndex(@intCast(record.start), @intCast(record.finish), @intCast(record.period));
    if (marked(&s.known, bit)) return;
    s.known[bit / 64] |= @as(u64, 1) << @intCast(bit % 64);
    if (is_generated) s.generated[bit / 64] |= @as(u64, 1) << @intCast(bit % 64);
    var at = s.record_count;
    while (at > 0 and less(record, s.records[at - 1])) : (at -= 1) s.records[at] = s.records[at - 1];
    s.records[at] = record;
    s.record_count += 1;
}

fn factorsValid(s: *const State) bool {
    if (s.factor_count == 0 or s.factor_count > s.n) return false;
    var position: usize = 0;
    for (0..s.factor_count) |f| {
        const a = s.starts[f];
        const b = s.ends[f];
        const c = s.copies[f];
        if (a < 0 or b <= a or @as(usize, @intCast(b)) > s.n or @as(usize, @intCast(a)) != position) return false;
        if (f == 0) {
            if (a != 0 or b != 1 or c != -1) return false;
            position = 1;
            continue;
        }
        const start: usize = @intCast(a);
        var longest: usize = 0;
        for (0..start) |earlier| longest = @max(longest, lce(s, earlier, start));
        const expected_end = @min(s.n, start + longest + 1);
        if (@as(usize, @intCast(b)) != expected_end) return false;
        const prefix = expected_end - start - 1;
        if (prefix == 0) {
            if (c != -1) return false;
        } else if (c < 0 or @as(usize, @intCast(c)) >= start or lce(s, @intCast(c), start) != prefix) return false;
        position = expected_end;
    }
    return position == s.n;
}

fn mismatches(s: *const State, start: usize, finish: usize, period: usize) usize {
    var errors: usize = 0;
    for (start..finish - period) |i| if (s.word[i] != s.word[i + period]) { errors += 1; };
    return errors;
}

fn seedValid(s: *const State, r: Record) bool {
    if (r.start < 0 or r.finish <= r.start or @as(usize, @intCast(r.finish)) > s.n or r.period < 1) return false;
    const a: usize = @intCast(r.start);
    const b: usize = @intCast(r.finish);
    const p: usize = @intCast(r.period);
    if (p > s.n / 2 or b - a < 2 * p) return false;
    const errors = mismatches(s, a, b, p);
    if (errors != @as(usize, @intCast(r.errors)) or errors > s.budget) return false;
    if (a > 0 and errors + @intFromBool(s.word[a - 1] != s.word[a + p - 1]) <= s.budget) return false;
    if (b < s.n and errors + @intFromBool(s.word[b - p] != s.word[b]) <= s.budget) return false;
    return true;
}

fn propagate(s: *State) void {
    for (0..s.factor_count) |f| {
        const a: usize = @intCast(s.starts[f]);
        const b: usize = @intCast(s.ends[f]);
        const c: usize = @intCast(s.copies[f]);
        const copied = b - a - 1;
        if (copied == 0) continue;
        const delta = a - c;
        const copy_end = c + copied;
        for (a + 1..b - 1) |target| {
            const source_start = target - delta;
            var index: usize = 0;
            while (index < s.record_count and s.records[index].start < @as(i32, @intCast(source_start))) : (index += 1) {}
            while (index < s.record_count and s.records[index].start == @as(i32, @intCast(source_start))) {
                const source = s.records[index];
                if (@as(usize, @intCast(source.finish)) > copy_end) break;
                const target_end = @as(usize, @intCast(source.finish)) + delta;
                if (target_end <= b - 2) addRecord(s, .{ .start = @intCast(target), .finish = @intCast(target_end), .period = source.period, .errors = source.errors }, true);
                index += 1;
            }
        }
    }
}

fn put(out: [*c]u8, offset: usize, value: u64) void {
    for (0..8) |byte| out[offset + byte] = @intCast((value >> @intCast(8 * byte)) & 255);
}

export fn k_repetition_within_factor_copy_propagation(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(N)) or input[1] < 0 or input[1] > @as(i64, @intCast(K))) return -1;
    var s = State{};
    s.n = @intCast(input[0]);
    s.budget = @intCast(input[1]);
    if (length < s.n + 3) return -1;
    var cursor: usize = 2;
    for (0..s.n) |i| {
        if (input[cursor] < 0 or input[cursor] > 5) return -1;
        s.word[i] = @intCast(input[cursor]);
        cursor += 1;
    }
    for (0..s.n - 1) |i| if (s.word[i] == s.word[s.n - 1]) return -1;
    if (cursor >= length or input[cursor] < 1 or input[cursor] > @as(i64, @intCast(s.n))) return -1;
    s.factor_count = @intCast(input[cursor]);
    cursor += 1;
    if (cursor + 3 * s.factor_count >= length) return -1;
    for (0..s.factor_count) |i| {
        const a = input[cursor];
        const b = input[cursor + 1];
        const c = input[cursor + 2];
        if (a < 0 or a > @as(i64, @intCast(s.n)) or b < 0 or b > @as(i64, @intCast(s.n)) or c < -1 or c > @as(i64, @intCast(s.n))) return -1;
        s.starts[i] = @intCast(a);
        s.ends[i] = @intCast(b);
        s.copies[i] = @intCast(c);
        cursor += 3;
    }
    if (cursor >= length or !factorsValid(&s)) return -1;
    const seed_count_value = input[cursor];
    cursor += 1;
    if (seed_count_value < 0 or seed_count_value > @as(i64, @intCast(MAX_RECORDS)) or cursor + 4 * @as(usize, @intCast(seed_count_value)) != length) return -1;
    const seed_count: usize = @intCast(seed_count_value);
    for (0..seed_count) |_| {
        const a = input[cursor]; const b = input[cursor + 1]; const p = input[cursor + 2]; const e = input[cursor + 3];
        if (a < 0 or a > @as(i64, @intCast(s.n)) or b < 0 or b > @as(i64, @intCast(s.n)) or p < 0 or p > @as(i64, @intCast(s.n)) or e < 0 or e > K) return -1;
        const record = Record{ .start = @intCast(a), .finish = @intCast(b), .period = @intCast(p), .errors = @intCast(e) };
        if (!seedValid(&s, record)) return -1;
        addRecord(&s, record, false);
        cursor += 4;
    }
    propagate(&s);
    var count: usize = 0;
    for (0..s.record_count) |i| {
        const r = s.records[i];
        if (marked(&s.generated, bitIndex(@intCast(r.start), @intCast(r.finish), @intCast(r.period)))) count += 1;
    }
    const bytes = 8 + 32 * count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null or capacity < bytes) return -2;
    put(output, 0, count);
    var offset: usize = 8;
    for (0..s.record_count) |i| {
        const r = s.records[i];
        if (!marked(&s.generated, bitIndex(@intCast(r.start), @intCast(r.finish), @intCast(r.period)))) continue;
        put(output, offset, @intCast(r.start)); offset += 8;
        put(output, offset, @intCast(r.finish)); offset += 8;
        put(output, offset, @intCast(r.period)); offset += 8;
        put(output, offset, @intCast(r.errors)); offset += 8;
    }
    return @intCast(bytes);
}
