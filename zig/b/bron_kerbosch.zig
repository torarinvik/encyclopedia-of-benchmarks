const MAX_VERTICES = 5;

fn populationCount(value: u64) u32 {
    var bits = value;
    var count: u32 = 0;
    while (bits != 0) : (bits >>= 1) {
        count += @intCast(bits & 1);
    }
    return count;
}

fn search(vertex_count: usize, adjacency: [MAX_VERTICES]u64,
          clique: u64, possible: u64, excluded: u64) u64 {
    if (possible == 0 and excluded == 0) return @as(u64, 1) << @intCast(clique);

    var pivot: ?usize = null;
    var greatest_degree: u32 = 0;
    const pivot_choices = possible | excluded;
    for (0..vertex_count) |vertex| {
        if ((pivot_choices & (@as(u64, 1) << @intCast(vertex))) == 0) continue;
        const degree = populationCount(adjacency[vertex]);
        if (pivot == null or degree > greatest_degree) {
            pivot = vertex;
            greatest_degree = degree;
        }
    }

    var candidates = possible;
    if (pivot) |vertex| candidates &= ~adjacency[vertex];
    var result: u64 = 0;
    var remaining_possible = possible;
    var remaining_excluded = excluded;
    for (0..vertex_count) |vertex| {
        const bit = @as(u64, 1) << @intCast(vertex);
        if ((candidates & bit) == 0) continue;
        result |= search(vertex_count, adjacency, clique | bit,
                         remaining_possible & adjacency[vertex], remaining_excluded & adjacency[vertex]);
        remaining_possible &= ~bit;
        remaining_excluded |= bit;
    }
    return result;
}

export fn bron_kerbosch(input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 7) return -1;
    if (input[0] < 0 or input[0] > MAX_VERTICES) return -1;
    const vertex_count: usize = @intCast(input[0]);
    if (length != vertex_count + 1) return -1;

    const vertex_mask = (@as(u64, 1) << @intCast(vertex_count)) - 1;
    var adjacency: [MAX_VERTICES]u64 = .{ 0, 0, 0, 0, 0 };
    for (0..vertex_count) |vertex| {
        const row = input[vertex + 1];
        if (row < 0 or (@as(u64, @intCast(row)) & ~vertex_mask) != 0) return -1;
        adjacency[vertex] = @as(u64, @intCast(row)) & ~(@as(u64, 1) << @intCast(vertex));
    }
    for (0..vertex_count) |left| {
        for (left + 1..vertex_count) |right| {
            if (((adjacency[left] >> @intCast(right)) & 1) != ((adjacency[right] >> @intCast(left)) & 1)) return -1;
        }
    }
    return @intCast(search(vertex_count, adjacency, 0, vertex_mask, 0));
}
