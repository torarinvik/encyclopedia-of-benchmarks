/// Clean-room bounded MaxCliqueDyn-style colored branch and bound.
const MAX_VERTICES: usize = 24;
const MAX_PARSEABLE_INPUT: usize = 26;

const Candidate = struct { vertex: usize = 0, bound: usize = 0 };
const Search = struct {
    adjacency: [MAX_VERTICES]u64 = [_]u64{0} ** MAX_VERTICES,
    chosen: [MAX_VERTICES]usize = [_]usize{0} ** MAX_VERTICES,
    chosen_count: usize = 0,
    best: usize = 0,
    steps: [MAX_VERTICES + 2]usize = [_]usize{0} ** (MAX_VERTICES + 2),
    prior_child_steps: [MAX_VERTICES + 2]usize = [_]usize{0} ** (MAX_VERTICES + 2),
    total_color_calls: usize = 0,
};

fn degreeOrder(search: *const Search, vertices: []const usize,
               ordered: *[MAX_VERTICES]Candidate) void {
    var ids: [MAX_VERTICES]usize = [_]usize{0} ** MAX_VERTICES;
    var degrees: [MAX_VERTICES]usize = [_]usize{0} ** MAX_VERTICES;
    var maximum_degree: usize = 0;
    for (vertices, 0..) |vertex, i| {
        ids[i] = vertex;
        for (vertices) |other| {
            if ((search.adjacency[vertex] & (@as(u64, 1) << @intCast(other))) != 0)
                degrees[i] += 1;
        }
        maximum_degree = @max(maximum_degree, degrees[i]);
    }
    for (1..vertices.len) |i| {
        const id = ids[i];
        const degree = degrees[i];
        var j = i;
        while (j > 0 and (degrees[j - 1] < degree
            or (degrees[j - 1] == degree and ids[j - 1] > id))) {
            ids[j] = ids[j - 1];
            degrees[j] = degrees[j - 1];
            j -= 1;
        }
        ids[j] = id;
        degrees[j] = degree;
    }
    for (0..vertices.len) |i| {
        ordered[i] = .{ .vertex = ids[i], .bound = @min(i, maximum_degree) + 1 };
    }
}

fn expand(search: *Search, candidates: []const Candidate, level: usize) void {
    const parent_steps = search.steps[level - 1];
    search.steps[level] += parent_steps - search.prior_child_steps[level];
    search.prior_child_steps[level] = parent_steps;
    var count = candidates.len;
    while (count > 0) {
        if (search.chosen_count + candidates[count - 1].bound <= search.best) return;
        const vertex = candidates[count - 1].vertex;
        search.chosen[search.chosen_count] = vertex;
        search.chosen_count += 1;

        var neighbors: [MAX_VERTICES]usize = [_]usize{0} ** MAX_VERTICES;
        var neighbor_count: usize = 0;
        for (candidates[0 .. count - 1]) |candidate| {
            if ((search.adjacency[vertex] & (@as(u64, 1) << @intCast(candidate.vertex))) != 0) {
                neighbors[neighbor_count] = candidate.vertex;
                neighbor_count += 1;
            }
        }
        if (neighbor_count > 0) {
            const prior_steps = search.steps[level];
            search.steps[level] += 1;
            search.total_color_calls += 1;
            if (@as(u64, @intCast(prior_steps)) * 1000
                < @as(u64, @intCast(search.total_color_calls)) * 25) {
                var reordered: [MAX_VERTICES]Candidate = [_]Candidate{.{}} ** MAX_VERTICES;
                degreeOrder(search, neighbors[0..neighbor_count], &reordered);
                for (0..neighbor_count) |i| neighbors[i] = reordered[i].vertex;
            }

            var class_masks: [MAX_VERTICES]u64 = [_]u64{0} ** MAX_VERTICES;
            var colors: [MAX_VERTICES]usize = [_]usize{0} ** MAX_VERTICES;
            var class_count: usize = 0;
            for (0..neighbor_count) |i| {
                var color: usize = 0;
                while (color < class_count and
                    (class_masks[color] & search.adjacency[neighbors[i]]) != 0) color += 1;
                if (color == class_count) class_count += 1;
                colors[i] = color + 1;
                class_masks[color] |= @as(u64, 1) << @intCast(neighbors[i]);
            }

            const minimum_color = @max(search.best -| search.chosen_count + 1, 1);
            var child: [MAX_VERTICES]Candidate = [_]Candidate{.{}} ** MAX_VERTICES;
            var child_count: usize = 0;
            var color = minimum_color;
            while (color <= class_count) : (color += 1) {
                for (0..neighbor_count) |i| {
                    if (colors[i] == color) {
                        child[child_count] = .{ .vertex = neighbors[i], .bound = color };
                        child_count += 1;
                    }
                }
            }
            expand(search, child[0..child_count], level + 1);
        } else if (search.chosen_count > search.best) {
            search.best = search.chosen_count;
        }

        search.chosen_count -= 1;
        count -= 1;
    }
}

export fn konc_maxclique_dyn(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    if (n64 < 0 or n64 > MAX_VERTICES or length != 1 + @as(usize, @intCast(n64))) return -1;
    const n: usize = @intCast(n64);
    const domain = (@as(u64, 1) << @intCast(n)) - 1;
    var search = Search{};
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
    if (n == 0) return 0;
    var vertices: [MAX_VERTICES]usize = [_]usize{0} ** MAX_VERTICES;
    for (0..n) |vertex| vertices[vertex] = vertex;
    var roots: [MAX_VERTICES]Candidate = [_]Candidate{.{}} ** MAX_VERTICES;
    degreeOrder(&search, vertices[0..n], &roots);
    expand(&search, roots[0..n], 1);
    return @intCast(search.best);
}
