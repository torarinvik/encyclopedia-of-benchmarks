const MAX_N: usize = 4;
const MAX_PARSEABLE_LENGTH: usize = 34;

fn solve(values: []const i64) i64 {
    if (values.len < 1 or values.len > MAX_PARSEABLE_LENGTH) return -1;
    const n_raw = values[0];
    if (n_raw < 1 or n_raw > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(n_raw);
    if (values.len != 1 + 2 * n * n) return -1;
    const side = n * n;
    var men_rank: [MAX_N][MAX_N]i64 = [_][MAX_N]i64{[_]i64{0} ** MAX_N} ** MAX_N;
    var women_rank: [MAX_N][MAX_N]i64 = [_][MAX_N]i64{[_]i64{0} ** MAX_N} ** MAX_N;
    for (0..n) |man| {
        for (0..n) |woman| {
            const rank = values[1 + man * n + woman];
            if (rank < 0 or rank > n_raw) return -1;
            men_rank[man][woman] = rank;
        }
    }
    for (0..n) |woman| {
        for (0..n) |man| {
            const rank = values[1 + side + woman * n + man];
            if (rank < 0 or rank > n_raw or ((rank > 0) != (men_rank[man][woman] > 0))) return -1;
            women_rank[woman][man] = rank;
        }
    }
    for (0..n) |person| {
        var maximum: i64 = 0;
        for (0..n) |partner| maximum = @max(maximum, men_rank[person][partner]);
        var level: i64 = 1;
        while (level <= maximum) : (level += 1) {
            var found = false;
            for (0..n) |partner| {
                if (men_rank[person][partner] == level) found = true;
            }
            if (!found) return -1;
        }
        maximum = 0;
        for (0..n) |partner| maximum = @max(maximum, women_rank[person][partner]);
        level = 1;
        while (level <= maximum) : (level += 1) {
            var found = false;
            for (0..n) |partner| {
                if (women_rank[person][partner] == level) found = true;
            }
            if (!found) return -1;
        }
    }

    var alive: [MAX_N][MAX_N]bool = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var engaged: [MAX_N][MAX_N]bool = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var proposed: [MAX_N]bool = [_]bool{false} ** MAX_N;
    for (0..n) |man| {
        for (0..n) |woman| {
            alive[man][woman] = men_rank[man][woman] > 0;
        }
    }
    while (true) {
        var proposer: ?usize = null;
        for (0..n) |man| {
            var has_engagement = false;
            var has_choice = false;
            for (0..n) |woman| {
                has_engagement = has_engagement or engaged[man][woman];
                has_choice = has_choice or alive[man][woman];
            }
            if (proposer == null and !has_engagement and has_choice) proposer = man;
        }
        if (proposer == null) break;
        const man = proposer.?;
        var head_rank = n_raw + 1;
        for (0..n) |woman| {
            if (alive[man][woman]) head_rank = @min(head_rank, men_rank[man][woman]);
        }
        for (0..n) |woman| {
            if (!alive[man][woman] or men_rank[man][woman] != head_rank) continue;
            proposed[woman] = true;
            engaged[man][woman] = true;
            for (0..n) |successor| {
                if (alive[successor][woman]
                    and women_rank[woman][successor] > women_rank[woman][man]) {
                    engaged[successor][woman] = false;
                    alive[successor][woman] = false;
                }
            }
        }
        for (0..n) |woman| {
            var count: usize = 0;
            var tail_rank: i64 = 0;
            for (0..n) |other_man| {
                if (engaged[other_man][woman]) count += 1;
                if (alive[other_man][woman]) tail_rank = @max(tail_rank, women_rank[woman][other_man]);
            }
            if (count > 1) {
                for (0..n) |other_man| {
                    engaged[other_man][woman] = false;
                    if (alive[other_man][woman] and women_rank[woman][other_man] == tail_rank)
                        alive[other_man][woman] = false;
                }
            }
        }
    }

    const base = n_raw + 1;
    var limit: i64 = 1;
    for (0..n) |_| {
        limit *= base;
    }
    var best_code: i64 = 0;
    var best_size: i64 = -1;
    var code: i64 = 0;
    while (code < limit) : (code += 1) {
        var used: usize = 0;
        var size: i64 = 0;
        var valid = true;
        var place = @divTrunc(limit, base);
        for (0..n) |person| {
            const woman: usize = @intCast(@mod(@divTrunc(code, place), base));
            if (woman < n) {
                const bit = @as(usize, 1) << @intCast(woman);
                if (!engaged[person][woman] or (used & bit) != 0) valid = false;
                used |= bit;
                size += 1;
            }
            if (person + 1 < n) place = @divTrunc(place, base);
        }
        if (valid and size > best_size) {
            best_size = size;
            best_code = code;
        }
    }
    var matched: [MAX_N]bool = [_]bool{false} ** MAX_N;
    var place = @divTrunc(limit, base);
    for (0..n) |man| {
        const woman: usize = @intCast(@mod(@divTrunc(best_code, place), base));
        if (woman < n) matched[woman] = true;
        if (man + 1 < n) place = @divTrunc(place, base);
    }
    for (0..n) |woman| {
        if (proposed[woman] and !matched[woman]) return -2;
    }
    return best_code;
}

export fn super_stable_matching_ties_incomplete(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    return solve(input.?[0..length]);
}
