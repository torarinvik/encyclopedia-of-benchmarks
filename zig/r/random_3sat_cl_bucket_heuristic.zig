const MaxN = 8;
const MaxM = 24;
const MaxParseableInput = 99;
const MaxWords = 44;
const MaxOutput = 352;

const Formula = struct {
    clauses: [MaxM][3]i32,
    lengths: [MaxM]usize,
    active: [MaxM]bool,
};
const Event = struct { literal: i64, kind: i64, bi: i64, bj: i64 };
const Flow = struct { s2: i64, s3: i64, den: i64 };
const Bucket = struct { i: usize, j: usize };

fn put(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn reduce(f: *Formula, n: usize, assigned: *[MaxN]i8, literal: i32) bool {
    const variable: usize = @intCast((if (literal > 0) literal else -literal) - 1);
    const value: i8 = if (literal > 0) 1 else -1;
    if (assigned[variable] != 0 and assigned[variable] != value) return false;
    assigned[variable] = value;
    for (0..MaxM) |c| {
        if (!f.active[c]) continue;
        var satisfied = false;
        for (0..f.lengths[c]) |j| if (f.clauses[c][j] == literal) { satisfied = true; };
        if (satisfied) { f.active[c] = false; continue; }
        var kept: usize = 0;
        for (0..f.lengths[c]) |j| if (f.clauses[c][j] != -literal) {
            f.clauses[c][kept] = f.clauses[c][j];
            kept += 1;
        };
        f.lengths[c] = kept;
        if (kept == 0) return false;
    }
    _ = n;
    return true;
}

fn propagate(f: *Formula, m: usize, assigned: *[MaxN]i8, events: *[MaxN]Event,
    count: *usize, record: bool) bool {
    while (true) {
        var unit: i32 = 0;
        for (0..m) |c| if (unit == 0 and f.active[c] and f.lengths[c] == 1) {
            unit = f.clauses[c][0];
        };
        if (unit == 0) return true;
        if (record) {
            events[count.*] = .{ .literal = unit, .kind = 1, .bi = -1, .bj = -1 };
            count.* += 1;
        }
        if (!reduce(f, MaxN, assigned, unit)) return false;
    }
}

fn member(f: *const Formula, m: usize, n: usize, assigned: *const [MaxN]i8,
    bi: usize, bj: usize) i32 {
    var positive: [MaxN]usize = @splat(0);
    var negative: [MaxN]usize = @splat(0);
    for (0..m) |c| if (f.active[c]) {
        for (0..f.lengths[c]) |j| {
            const x = f.clauses[c][j];
            const v: usize = @intCast((if (x > 0) x else -x) - 1);
            if (x > 0) positive[v] += 1 else negative[v] += 1;
        }
    };
    for (0..n) |v| {
        if (assigned[v] != 0) continue;
        const p = @min(10, positive[v]);
        const q = @min(10, negative[v]);
        if (p == bi and q == bj) return @intCast(v + 1);
        if (q == bi and p == bj) return -@as(i32, @intCast(v + 1));
    }
    return 0;
}

fn flows(f: *const Formula, m: usize, n: usize) Flow {
    var p2: [MaxN]i64 = @splat(0); var n2: [MaxN]i64 = @splat(0);
    var p3: [MaxN]i64 = @splat(0); var n3: [MaxN]i64 = @splat(0);
    var clauses2: i64 = 0;
    for (0..m) |c| if (f.active[c]) {
        if (f.lengths[c] == 2) clauses2 += 1;
        if (f.lengths[c] == 2 or f.lengths[c] == 3) {
            for (0..f.lengths[c]) |j| {
                const x = f.clauses[c][j];
                const v: usize = @intCast((if (x > 0) x else -x) - 1);
                if (f.lengths[c] == 2) {
                    if (x > 0) p2[v] += 1 else n2[v] += 1;
                } else {
                    if (x > 0) p3[v] += 1 else n3[v] += 1;
                }
            }
        }
    };
    var s2: i64 = 0; var s3: i64 = 0;
    for (0..m) |c| if (f.active[c] and f.lengths[c] == 2) {
        for (0..2) |j| {
            const x = -f.clauses[c][j];
            const v: usize = @intCast((if (x > 0) x else -x) - 1);
            if (x > 0) { s2 += p2[v]; s3 += p3[v]; }
            else { s2 += n2[v]; s3 += n3[v]; }
        }
    };
    _ = n;
    return .{ .s2 = s2, .s3 = s3, .den = if (clauses2 == 0) 1 else 2 * clauses2 };
}

fn choose(f: *const Formula, m: usize, n: usize, assigned: *const [MaxN]i8) ?Bucket {
    const old = flows(f, m, n);
    var found = false;
    var best_num: i64 = 0; var best_den: i64 = 1;
    var best_i: usize = 0; var best_j: usize = 0;
    for (0..11) |bi| for (0..11) |bj| {
        const literal = member(f, m, n, assigned, bi, bj);
        if (literal == 0) continue;
        var trial = f.*;
        var trial_assigned = assigned.*;
        var ignored: [MaxN]Event = @splat(.{ .literal = 0, .kind = 0, .bi = 0, .bj = 0 });
        var ignored_count: usize = 0;
        if (!reduce(&trial, n, &trial_assigned, literal)) continue;
        if (!propagate(&trial, m, &trial_assigned, &ignored, &ignored_count, false)) continue;
        const next = flows(&trial, m, n);
        var numerator = next.s2 * old.den - old.s2 * next.den;
        var denominator = next.s3 * old.den - old.s3 * next.den;
        if (denominator == 0) continue;
        if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
        if (!found or numerator * best_den > best_num * denominator or
            (numerator * best_den == best_num * denominator and
             (bi < best_i or (bi == best_i and bj < best_j)))) {
            found = true; best_num = numerator; best_den = denominator; best_i = bi; best_j = bj;
        }
    };
    if (!found) return null;
    return .{ .i = best_i, .j = best_j };
}

export fn random_3sat_cl_bucket_heuristic(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MaxParseableInput) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > MaxN or input[1] < 0 or input[1] > MaxM) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 4 * m) return -1;
    var f = Formula{ .clauses = @splat(@splat(0)), .lengths = @splat(0), .active = @splat(false) };
    for (0..m) |c| {
        const base = 2 + 4 * c;
        const raw_k = input[base];
        if (raw_k < 1 or raw_k > 3) return -1;
        const k: usize = @intCast(raw_k);
        var seen: [MaxN]bool = @splat(false);
        for (0..3) |j| {
            const raw = input[base + 1 + j];
            if (j < k) {
                if (raw == 0 or raw < -@as(i64, @intCast(n)) or raw > @as(i64, @intCast(n))) return -1;
                const v: usize = @intCast((if (raw > 0) raw else -raw) - 1);
                if (seen[v]) return -1;
                seen[v] = true;
                f.clauses[c][j] = @intCast(raw);
            } else if (raw != 0) return -1;
        }
        f.lengths[c] = k; f.active[c] = true;
    }

    var assigned: [MaxN]i8 = @splat(0);
    var events: [MaxN]Event = @splat(.{ .literal = 0, .kind = 0, .bi = 0, .bj = 0 });
    var count: usize = 0; var status: i64 = 0;
    if (!propagate(&f, m, &assigned, &events, &count, true)) status = 1;
    while (status == 0) {
        var pending = false;
        for (0..n) |v| if (assigned[v] == 0) { pending = true; };
        if (!pending) break;
        const selected = choose(&f, m, n, &assigned) orelse { status = 2; break; };
        const literal = member(&f, m, n, &assigned, selected.i, selected.j);
        if (literal == 0) { status = 2; break; }
        events[count] = .{ .literal = literal, .kind = 0, .bi = @intCast(selected.i), .bj = @intCast(selected.j) };
        count += 1;
        if (!reduce(&f, n, &assigned, literal)) { status = 1; break; }
        if (!propagate(&f, m, &assigned, &events, &count, true)) { status = 1; break; }
    }
    var words: [MaxWords]i64 = @splat(0);
    var at: usize = 0; words[at] = status; at += 1; words[at] = @intCast(n); at += 1;
    var assigned_count: usize = 0;
    for (0..n) |v| { if (assigned[v] != 0) assigned_count += 1; }
    words[at] = @intCast(assigned_count); at += 1;
    for (0..n) |v| { words[at] = assigned[v]; at += 1; }
    words[at] = @intCast(count); at += 1;
    for (0..count) |e| {
        words[at] = events[e].literal; at += 1; words[at] = events[e].kind; at += 1;
        words[at] = events[e].bi; at += 1; words[at] = events[e].bj; at += 1;
    }
    const bytes = at * 8;
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MaxOutput]u8 = @splat(0);
    for (0..at) |i| put(&staged, 8 * i, words[i]);
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
