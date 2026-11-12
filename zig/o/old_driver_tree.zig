const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_INPUT: usize = 195;
const MAX_RUNS: usize = 36;

const Run = struct { left: i64 = 0, right: i64 = 0, value: i64 = 0 };
const Operation = struct { kind: i64 = 0, left: i64 = 0, right: i64 = 0, arg: i64 = 0, extra: i64 = 0 };

fn lowerBound(runs: *const [MAX_RUNS]Run, count: usize, point: i64) usize {
    var lo: usize = 0;
    var hi = count;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        if (runs[mid].left < point) lo = mid + 1 else hi = mid;
    }
    return lo;
}
fn splitAt(runs: *[MAX_RUNS]Run, count: *usize, point: i64, n: i64) void {
    if (point <= 0 or point >= n) return;
    const at = lowerBound(runs, count.*, point);
    if (at < count.* and runs[at].left == point) return;
    const old = runs[at - 1];
    var i = count.*;
    while (i > at) : (i -= 1) runs[i] = runs[i - 1];
    runs[at - 1].right = point - 1;
    runs[at] = .{ .left = point, .right = old.right, .value = old.value };
    count.* += 1;
}
fn coalesce(runs: *[MAX_RUNS]Run, count: *usize) void {
    var write: usize = 0;
    for (0..count.*) |read| {
        if (write > 0 and runs[write - 1].right + 1 == runs[read].left and runs[write - 1].value == runs[read].value) {
            runs[write - 1].right = runs[read].right;
        } else { runs[write] = runs[read]; write += 1; }
    }
    count.* = write;
}
fn modularPower(base: i64, exponent_input: i64, modulus: i64) i64 {
    var exponent = exponent_input;
    var value = @mod(base, modulus);
    var result: i64 = @mod(1, modulus);
    while (exponent > 0) : (exponent >>= 1) {
        if ((exponent & 1) != 0) result = @mod(result * value, modulus);
        value = @mod(value * value, modulus);
    }
    return result;
}
fn storeLe(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn old_driver_tree(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const nv = input[0];
    const qv = input[1];
    if (nv < 1 or nv > MAX_N or qv < 0 or qv > MAX_Q or length < 2 + @as(usize, @intCast(nv))) return -1;
    const n: usize = @intCast(nv);
    const q: usize = @intCast(qv);
    var initial: [MAX_N]i64 = @splat(0);
    var ops: [MAX_Q]Operation = @splat(.{});
    var cursor: usize = 2 + n;
    var answer_count: usize = 0;
    for (0..n) |i| { initial[i] = input[2 + i]; if (initial[i] < -1000 or initial[i] > 1000) return -1; }
    for (0..q) |i| {
        if (cursor >= length) return -1;
        const kind = input[cursor]; cursor += 1;
        const words: usize = if (kind == 3) 4 else if (kind >= 0 and kind <= 2) 3 else 0;
        if (words == 0 or length - cursor < words) return -1;
        var op = Operation{ .kind = kind, .left = input[cursor], .right = input[cursor + 1], .arg = input[cursor + 2] };
        cursor += 3;
        if (kind == 3) { op.extra = input[cursor]; cursor += 1; }
        if (op.left < 0 or op.left > op.right or op.right >= nv) return -1;
        if ((kind <= 1 and (op.arg < -1000 or op.arg > 1000)) or
            (kind == 2 and (op.arg < 1 or op.arg > op.right - op.left + 1)) or
            (kind == 3 and (op.arg < 0 or op.arg > 8 or op.extra < 1 or op.extra > 1_000_000_000))) return -1;
        if (kind >= 2) answer_count += 1;
        ops[i] = op;
    }
    if (cursor != length or length > 2 + MAX_N + 5 * MAX_Q) return -1;
    const required = 8 * answer_count;
    if (required > 0 and (output == null or capacity < required)) return -2;
    var runs: [MAX_RUNS]Run = @splat(.{});
    var run_count: usize = 0;
    for (0..n) |i| {
        if (run_count > 0 and runs[run_count - 1].value == initial[i]) runs[run_count - 1].right = @intCast(i)
        else { runs[run_count] = .{ .left = @intCast(i), .right = @intCast(i), .value = initial[i] }; run_count += 1; }
    }
    var written: usize = 0;
    for (0..q) |oi| {
        const op = ops[oi];
        if (op.kind <= 1) {
            splitAt(&runs, &run_count, op.right + 1, nv);
            splitAt(&runs, &run_count, op.left, nv);
            const start = lowerBound(&runs, run_count, op.left);
            const finish = lowerBound(&runs, run_count, op.right + 1);
            if (op.kind == 0) {
                const removed = finish - start;
                const old_count = run_count;
                for (finish..old_count) |i| runs[i - removed] = runs[i];
                run_count = old_count - removed;
                var i = run_count;
                while (i > start) : (i -= 1) runs[i] = runs[i - 1];
                runs[start] = .{ .left = op.left, .right = op.right, .value = op.arg };
                run_count += 1;
            } else {
                for (start..finish) |i| runs[i].value += op.arg;
            }
            coalesce(&runs, &run_count);
        } else if (op.kind == 2) {
            var ordered: [MAX_N]i64 = @splat(0);
            var used: usize = 0;
            for (0..run_count) |i| {
                const lo = @max(runs[i].left, op.left); const hi = @min(runs[i].right, op.right);
                if (lo <= hi) {
                    const width: usize = @intCast(hi - lo + 1);
                    for (0..width) |_| {
                        var at = used;
                        while (at > 0 and ordered[at - 1] > runs[i].value) : (at -= 1) ordered[at] = ordered[at - 1];
                        ordered[at] = runs[i].value;
                        used += 1;
                    }
                }
            }
            storeLe(output, 8 * written, ordered[@intCast(op.arg - 1)]); written += 1;
        } else {
            var total: i64 = 0;
            for (0..run_count) |i| {
                const lo = @max(runs[i].left, op.left); const hi = @min(runs[i].right, op.right);
                if (lo <= hi) total = @mod(total + (hi - lo + 1) * modularPower(runs[i].value, op.arg, op.extra), op.extra);
            }
            storeLe(output, 8 * written, total); written += 1;
        }
    }
    return @intCast(required);
}
