/// Ordered candidate-intersection search with a suffix-optimum bound.
const MAX_VERTICES: usize = 24;
const MAX_PARSEABLE_INPUT: usize = 26;

const CliqueSearch = struct {
    adjacency: [MAX_VERTICES]u64 = [_]u64{0} ** MAX_VERTICES,
    suffix_best: [MAX_VERTICES]i64 = [_]i64{0} ** MAX_VERTICES,
    best: i64 = 0,
};

fn bitCount(bits_input: u64) i64 {
    var bits = bits_input;
    var count: i64 = 0;
    while (bits != 0) { bits &= bits - 1; count += 1; }
    return count;
}

fn searchClique(search: *CliqueSearch, candidates: u64, chosen: i64) bool {
    if (candidates == 0) {
        if (chosen > search.best) { search.best = chosen; return true; }
        return false;
    }
    var remaining = candidates;
    while (remaining != 0) {
        if (chosen + bitCount(remaining) <= search.best) return false;
        const bit = remaining & (~remaining + 1);
        const vertex: usize = @intCast(@ctz(bit));
        remaining &= ~bit;
        if (chosen + search.suffix_best[vertex] <= search.best) return false;
        if (searchClique(search, remaining & search.adjacency[vertex], chosen + 1)) return true;
    }
    return false;
}

export fn oi_wiki_maximum_clique_branch_bound(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    if (n64 < 0 or n64 > @as(i64, MAX_VERTICES)
        or length != 1 + @as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);
    const domain = (@as(u64, 1) << @intCast(n)) - 1;
    var search = CliqueSearch{};
    for (0..n) |vertex| {
        const row = input[1 + vertex];
        if (row < 0 or (@as(u64, @intCast(row)) & ~domain) != 0) return -1;
        search.adjacency[vertex] = @intCast(row);
        if ((search.adjacency[vertex] & (@as(u64, 1) << @intCast(vertex))) != 0) return -1;
    }
    for (0..n) |left| {
        for (left + 1..n) |right| {
            const forward = (search.adjacency[left] & (@as(u64, 1) << @intCast(right))) != 0;
            const reverse = (search.adjacency[right] & (@as(u64, 1) << @intCast(left))) != 0;
            if (forward != reverse) return -1;
        }
    }
    var root = n;
    while (root > 0) {
        root -= 1;
        const greater = domain & ~((@as(u64, 1) << @intCast(root + 1)) - 1);
        _ = searchClique(&search, search.adjacency[root] & greater, 1);
        search.suffix_best[root] = search.best;
    }
    return search.best;
}
