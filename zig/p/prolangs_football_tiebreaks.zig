const Fraction = struct { numerator: i64, denominator: i64 };
const Group = struct { lo: usize, hi: usize, stage: usize };

fn sameDivision(v: [*]const i64, order: *[8]usize, lo: usize, hi: usize) bool {
    const first = 1 + 12 * order[lo];
    for (lo + 1..hi) |p| {
        const current = 1 + 12 * order[p];
        if (v[first + 1] != v[current + 1] or v[first + 2] != v[current + 2]) return false;
    }
    return true;
}

fn scoreFor(v: [*]const i64, n: usize, order: *[8]usize, lo: usize, hi: usize,
            team: usize, stage: usize, same_div: bool) Fraction {
    if (stage == 0) {
        const cells = n * n;
        const wins_start = 1 + 12 * n;
        const ties_start = wins_start + cells;
        var won: i64 = 0;
        var lost: i64 = 0;
        var tied: i64 = 0;
        for (lo..hi) |p| {
            const other = order[p];
            if (other == team) continue;
            won += v[wins_start + team * n + other];
            lost += v[wins_start + other * n + team];
            tied += v[ties_start + team * n + other];
        }
        const games = won + lost + tied;
        return .{ .numerator = 2 * won + tied, .denominator = if (games == 0) 1 else 2 * games };
    }
    const base = 1 + 12 * team;
    if (stage >= 1 and stage <= 3) {
        const field: usize = if (stage == 1) 3 else if (stage == 2) 5 else 7;
        const games = v[base + field + 1];
        return .{ .numerator = v[base + field], .denominator = if (games == 0) 1 else 2 * games };
    }
    if (stage == 4) return .{ .numerator = v[base + (if (same_div) 9 else 10)], .denominator = 1 };
    return .{ .numerator = v[base + 11], .denominator = 1 };
}

fn compare(a: Fraction, b: Fraction) i8 {
    const left = a.numerator * b.denominator;
    const right = b.numerator * a.denominator;
    return if (left > right) 1 else if (left < right) -1 else 0;
}

fn refine(v: [*]const i64, n: usize, order: *[8]usize, lo: usize, hi: usize,
          stage: usize, same_div: bool, output: *[8]Group, output_count: *usize) void {
    for (lo + 1..hi) |i| {
        const item = order[i];
        const item_score = scoreFor(v, n, order, lo, hi, item, stage, same_div);
        var j = i;
        while (j > lo) {
            const previous = scoreFor(v, n, order, lo, hi, order[j - 1], stage, same_div);
            if (compare(item_score, previous) <= 0) break;
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = item;
    }
    const best = scoreFor(v, n, order, lo, hi, order[lo], stage, same_div);
    var split = false;
    for (lo + 1..hi) |i| {
        if (compare(best, scoreFor(v, n, order, lo, hi, order[i], stage, same_div)) != 0) split = true;
    }
    if (!split) {
        output[output_count.*] = .{ .lo = lo, .hi = hi, .stage = stage + 1 };
        output_count.* += 1;
        return;
    }
    var start = lo;
    while (start < hi) {
        const value = scoreFor(v, n, order, lo, hi, order[start], stage, same_div);
        var end = start + 1;
        while (end < hi and compare(value, scoreFor(v, n, order, lo, hi, order[end], stage, same_div)) == 0) end += 1;
        output[output_count.*] = .{ .lo = start, .hi = end, .stage = 0 };
        output_count.* += 1;
        start = end;
    }
}

fn sweepResult(v: [*]const i64, n: usize, order: *[8]usize, lo: usize, hi: usize) i32 {
    const cells = n * n;
    const wins_start = 1 + 12 * n;
    const ties_start = wins_start + cells;
    for (0..hi - lo) |position| {
        const team = order[lo + position];
        var win = true;
        var lose = true;
        for (lo..hi) |p| {
            const other = order[p];
            if (other == team) continue;
            const won = v[wins_start + team * n + other];
            const lost = v[wins_start + other * n + team];
            const tied = v[ties_start + team * n + other];
            if (won + lost + tied == 0 or tied != 0) { win = false; lose = false; }
            if (lost != 0) win = false;
            if (won != 0) lose = false;
        }
        if (win) return @intCast(position + 1);
        if (lose) return -@as(i32, @intCast(position + 1));
    }
    return 0;
}

pub export fn prolangs_football_tiebreaks(input: ?[*]const i64, length: usize) i64 {
    const v = input orelse return -2;
    if (length < 1 or v[0] < 2 or v[0] > 8) return -2;
    const n: usize = @intCast(v[0]);
    const cells = n * n;
    if (length != 1 + 12 * n + 2 * cells) return -2;
    var order: [8]usize = [_]usize{0} ** 8;
    for (0..n) |i| {
        const base = 1 + 12 * i;
        const id = v[base];
        if (id < 0 or id > 31 or v[base + 1] < 0 or v[base + 1] > 1 or v[base + 2] < 0 or v[base + 2] > 2) return -2;
        for ([_]usize{ 3, 5, 7 }) |field| {
            const points = v[base + field];
            const games = v[base + field + 1];
            if (games < 0 or games > 64 or points < 0 or points > 2 * games) return -2;
        }
        for (9..12) |field| if (v[base + field] < -4096 or v[base + field] > 4096) return -2;
        for (0..i) |previous| if (v[1 + 12 * previous] == id) return -2;
        order[i] = i;
    }
    const wins_start = 1 + 12 * n;
    const ties_start = wins_start + cells;
    for (0..n) |i| {
        for (0..n) |j| {
            const wins = v[wins_start + i * n + j];
            const ties = v[ties_start + i * n + j];
            if (wins < 0 or wins > 64 or ties < 0 or ties > 64 or
                (i == j and (wins != 0 or ties != 0)) or ties != v[ties_start + j * n + i]) return -2;
        }
    }
    for (1..n) |i| {
        const item = order[i];
        var j = i;
        while (j > 0 and (v[1 + 12 * order[j - 1] + 1] > v[1 + 12 * item + 1] or
            (v[1 + 12 * order[j - 1] + 1] == v[1 + 12 * item + 1] and v[1 + 12 * order[j - 1]] > v[1 + 12 * item]))) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = item;
    }
    var groups: [8]Group = undefined;
    var next: [8]Group = undefined;
    var group_count: usize = 1;
    groups[0] = .{ .lo = 0, .hi = n, .stage = 0 };
    while (true) {
        var next_count: usize = 0;
        var active = false;
        for (0..group_count) |g| {
            const lo = groups[g].lo;
            const hi = groups[g].hi;
            const stage = groups[g].stage;
            if (hi - lo <= 1 or stage >= 6) {
                next[next_count] = .{ .lo = lo, .hi = hi, .stage = 6 };
                next_count += 1;
                continue;
            }
            active = true;
            const same = sameDivision(v, &order, lo, hi);
            if (stage == 0) {
                if (same or hi - lo == 2) {
                    refine(v, n, &order, lo, hi, 0, same, &next, &next_count);
                } else {
                    const sweep = sweepResult(v, n, &order, lo, hi);
                    if (sweep > 0) {
                        const position: usize = lo + @as(usize, @intCast(sweep - 1));
                        const first = order[lo]; order[lo] = order[position]; order[position] = first;
                        next[next_count] = .{ .lo = lo, .hi = lo + 1, .stage = 0 }; next_count += 1;
                        next[next_count] = .{ .lo = lo + 1, .hi = hi, .stage = 0 }; next_count += 1;
                    } else if (sweep < 0) {
                        const position: usize = lo + @as(usize, @intCast(-sweep - 1));
                        const last = order[hi - 1]; order[hi - 1] = order[position]; order[position] = last;
                        next[next_count] = .{ .lo = lo, .hi = hi - 1, .stage = 0 }; next_count += 1;
                        next[next_count] = .{ .lo = hi - 1, .hi = hi, .stage = 0 }; next_count += 1;
                    } else {
                        next[next_count] = .{ .lo = lo, .hi = hi, .stage = 1 }; next_count += 1;
                    }
                }
            } else if (stage == 1 and !same) {
                next[next_count] = .{ .lo = lo, .hi = hi, .stage = 2 }; next_count += 1;
            } else if (stage == 3) {
                var skip_common = false;
                for (lo..hi) |p| if (v[1 + 12 * order[p] + 8] < 4) { skip_common = true; };
                if (skip_common) { next[next_count] = .{ .lo = lo, .hi = hi, .stage = 4 }; next_count += 1; }
                else refine(v, n, &order, lo, hi, stage, same, &next, &next_count);
            } else refine(v, n, &order, lo, hi, stage, same, &next, &next_count);
        }
        for (0..next_count) |g| groups[g] = next[g];
        group_count = next_count;
        if (!active) break;
    }
    var result: i64 = 0;
    for (0..n) |i| result = result * 32 + v[1 + 12 * order[i]];
    return result;
}
