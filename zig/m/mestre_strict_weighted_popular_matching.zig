// Clean-room bounded implementation of Mestre's strict weighted profile.
const A: usize = 4;
const J: usize = 5;
const N: usize = 9;
const PARSEABLE: usize = 31;
const INF: i64 = 1_000_000_000;

fn lambdaMin(a: usize, target: usize, rows: *const [A][N]usize,
    rowLen: *const [A]usize, fCategory: *const [N]i32,
    label: *const [N]i64) i64 {
    var best: i64 = INF;
    for (0..rowLen[a]) |i| {
        const job = rows[a][i];
        if (job == target) break;
        if (fCategory[job] >= 0) best = @min(best, label[job]);
    }
    return best;
}

fn augment(a: usize, edges: *const [A][2]usize, edgeCount: *const [A]usize,
    owner: *[N]i32, seen: *[N]bool) bool {
    for (0..edgeCount[a]) |i| {
        const job = edges[a][i];
        if (seen[job]) continue;
        seen[job] = true;
        const previous = owner[job];
        if (previous < 0 or augment(@intCast(previous), edges, edgeCount, owner, seen)) {
            owner[job] = @intCast(a);
            return true;
        }
    }
    return false;
}

fn solve(applicants: usize, jobs: usize, weights: *const [A]i64,
    lengths: *const [A]usize, listed: *const [A][J]usize) i64 {
    var rows = [_][N]usize{[_]usize{0} ** N} ** A;
    var rowLen = [_]usize{0} ** A;
    for (0..applicants) |a| {
        for (0..lengths[a]) |i| { rows[a][rowLen[a]] = listed[a][i]; rowLen[a] += 1; }
        rows[a][rowLen[a]] = jobs + a; rowLen[a] += 1;
    }
    var categoryWeight = [_]i64{0} ** A;
    var categoryCount: usize = 0;
    for (0..applicants) |a| {
        var found = false;
        for (0..categoryCount) |c| if (categoryWeight[c] == weights[a]) { found = true; };
        if (!found) { categoryWeight[categoryCount] = weights[a]; categoryCount += 1; }
    }
    for (0..categoryCount) |i| {
        for (i + 1..categoryCount) |j| if (categoryWeight[j] > categoryWeight[i]) {
            const tmp = categoryWeight[i]; categoryWeight[i] = categoryWeight[j]; categoryWeight[j] = tmp;
        };
    }
    var category = [_]usize{0} ** A;
    for (0..applicants) |a| {
        while (categoryWeight[category[a]] != weights[a]) : (category[a] += 1) {}
    }
    var first = [_]usize{0} ** A;
    var second = [_]usize{N} ** A;
    var fCategory = [_]i32{-1} ** N;
    var higher = [_]bool{false} ** N;
    var label = [_]i64{INF} ** N;
    for (0..categoryCount) |c| {
        for (0..applicants) |a| if (category[a] == c) {
            for (0..rowLen[a]) |i| if (!higher[rows[a][i]]) { first[a] = rows[a][i]; break; };
        };
        for (0..applicants) |a| if (category[a] == c) {
            fCategory[first[a]] = @intCast(c); higher[first[a]] = true;
        };
    }
    for (0..applicants) |a| {
        for (0..rowLen[a]) |i| {
            const p = rows[a][i];
            if (fCategory[p] < 0 or @as(usize, @intCast(fCategory[p])) > category[a]) { second[a] = p; break; }
        }
    }
    var keepFirst = [_]bool{true} ** A;
    var keepSecond = [_]bool{false} ** A;
    for (0..applicants) |a| keepSecond[a] = second[a] != N;
    for (0..categoryCount) |c| {
        const weight = categoryWeight[c];
        if (c == 0) {
            for (0..applicants) |a| if (category[a] == c) { label[first[a]] = weight; };
            continue;
        }
        for (0..applicants) |a| if (category[a] == c and lambdaMin(a, first[a], &rows, &rowLen, &fCategory, &label) < weight) return 0;
        for (0..N) |p| if (fCategory[p] == @as(i32, @intCast(c))) {
            var group = [_]usize{0} ** A;
            var count: usize = 0;
            for (0..applicants) |a| if (category[a] == c and first[a] == p) { group[count] = a; count += 1; };
            if (count == 1) {
                const earlier = lambdaMin(group[0], p, &rows, &rowLen, &fCategory, &label);
                label[p] = if (earlier >= INF) weight else @min(weight, earlier - weight);
            } else {
                label[p] = weight;
                for (0..count) |i| {
                    const a = group[i];
                    if (lambdaMin(a, p, &rows, &rowLen, &fCategory, &label) < 2 * weight) keepFirst[a] = false;
                }
            }
        };
        for (0..applicants) |a| if (category[a] == c and second[a] != N
            and lambdaMin(a, second[a], &rows, &rowLen, &fCategory, &label) < weight) { keepSecond[a] = false; };
    }
    var isFirst = [_]bool{false} ** N;
    for (0..applicants) |a| isFirst[first[a]] = true;
    for (0..N) |p| if (isFirst[p]) {
        var eligible = false;
        for (0..applicants) |a| if (first[a] == p and keepFirst[a]) { eligible = true; };
        if (!eligible) return 0;
    };
    var edges = [_][2]usize{[_]usize{0} ** 2} ** A;
    var edgeCount = [_]usize{0} ** A;
    for (0..applicants) |a| {
        if (keepFirst[a]) { edges[a][edgeCount[a]] = first[a]; edgeCount[a] += 1; }
        if (keepSecond[a] and second[a] != N and !isFirst[second[a]]) {
            edges[a][edgeCount[a]] = second[a]; edgeCount[a] += 1;
        }
        if (edgeCount[a] == 0) return 0;
    }
    var owner = [_]i32{-1} ** N;
    for (0..applicants) |a| {
        var seen = [_]bool{false} ** N;
        if (!augment(a, &edges, &edgeCount, &owner, &seen)) return 0;
    }
    return 1;
}

export fn mestre_strict_weighted_popular_matching(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > PARSEABLE) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > A or values[1] < 1 or values[1] > J) return -1;
    const applicants: usize = @intCast(values[0]);
    const jobs: usize = @intCast(values[1]);
    if (length < 2 + 2 * applicants) return -1;
    var weights = [_]i64{0} ** A;
    var lengths = [_]usize{0} ** A;
    var total: usize = 0;
    for (0..applicants) |a| {
        weights[a] = values[2 + a];
        const size = values[2 + applicants + a];
        if (weights[a] < 1 or weights[a] > 1000 or size < 1 or size > jobs) return -1;
        lengths[a] = @intCast(size); total += lengths[a];
    }
    if (length != 2 + 2 * applicants + total) return -1;
    var listed = [_][J]usize{[_]usize{0} ** J} ** A;
    var cursor: usize = 2 + 2 * applicants;
    for (0..applicants) |a| for (0..lengths[a]) |i| {
        const value = values[cursor]; cursor += 1;
        if (value < 0 or value >= jobs) return -1;
        const p: usize = @intCast(value);
        for (0..i) |k| if (listed[a][k] == p) return -1;
        listed[a][i] = p;
    };
    return solve(applicants, jobs, &weights, &lengths, &listed);
}
