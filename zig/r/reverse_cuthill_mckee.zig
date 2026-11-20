const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 28;
const MAX_INPUT_LENGTH: usize = 59;

export fn reverse_cuthill_mckee(input: ?[*]const i64, length: usize) i64 {
    const values_ptr = input orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = values_ptr[0..length];
    const n_value = values[0];
    const m_value = values[1];
    if (n_value < 1 or n_value > MAX_VERTICES or m_value < 0 or m_value > MAX_EDGES) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (m > n * (n - 1) / 2 or length != 2 + 2 * m) return -1;

    var adjacency: [MAX_VERTICES][MAX_VERTICES]bool = @splat(@splat(false));
    for (0..m) |edge| {
        const left_value = values[2 + 2 * edge];
        const right_value = values[3 + 2 * edge];
        if (left_value < 0 or left_value >= @as(i64, @intCast(n))
            or right_value < 0 or right_value >= @as(i64, @intCast(n))
            or left_value == right_value) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        if (adjacency[left][right] or adjacency[right][left]) return -1;
        adjacency[left][right] = true;
        adjacency[right][left] = true;
    }

    var degree: [MAX_VERTICES]usize = @splat(0);
    for (0..n) |vertex| {
        for (0..n) |neighbor| {
            if (adjacency[vertex][neighbor]) degree[vertex] += 1;
        }
    }

    var visited: [MAX_VERTICES]bool = @splat(false);
    var queue: [MAX_VERTICES]usize = @splat(0);
    var order: [MAX_VERTICES]usize = @splat(0);
    var order_length: usize = 0;
    var visited_count: usize = 0;
    while (visited_count < n) {
        var root = n;
        for (0..n) |vertex| {
            if (visited[vertex]) continue;
            if (root == n or degree[vertex] < degree[root]
                or (degree[vertex] == degree[root] and vertex < root)) root = vertex;
        }

        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = root;
        visited[root] = true;
        visited_count += 1;
        order[order_length] = root;
        order_length += 1;
        while (head < tail) {
            const vertex = queue[head];
            head += 1;
            var fresh: [MAX_VERTICES]usize = @splat(0);
            var fresh_count: usize = 0;
            for (0..n) |neighbor| {
                if (!adjacency[vertex][neighbor] or visited[neighbor]) continue;
                var insert_at = fresh_count;
                while (insert_at > 0) {
                    const previous = fresh[insert_at - 1];
                    if (degree[previous] < degree[neighbor]
                        or (degree[previous] == degree[neighbor] and previous < neighbor)) break;
                    fresh[insert_at] = previous;
                    insert_at -= 1;
                }
                fresh[insert_at] = neighbor;
                fresh_count += 1;
            }
            for (0..fresh_count) |index| {
                const neighbor = fresh[index];
                visited[neighbor] = true;
                visited_count += 1;
                queue[tail] = neighbor;
                tail += 1;
                order[order_length] = neighbor;
                order_length += 1;
            }
        }
    }

    var left: usize = 0;
    var right = order_length;
    while (left < right) {
        right -= 1;
        if (left >= right) break;
        const temporary = order[left];
        order[left] = order[right];
        order[right] = temporary;
        left += 1;
    }

    var position: [MAX_VERTICES]usize = @splat(0);
    var rank_word: i64 = 0;
    for (0..n) |rank| {
        const vertex = order[rank];
        position[vertex] = rank;
        rank_word |= @as(i64, @intCast(vertex)) << @as(u6, @intCast(3 * rank));
    }
    var bandwidth: usize = 0;
    for (0..n) |left_vertex| {
        for (left_vertex + 1..n) |right_vertex| {
            if (adjacency[left_vertex][right_vertex]) {
                const difference = if (position[left_vertex] >= position[right_vertex])
                    position[left_vertex] - position[right_vertex]
                else
                    position[right_vertex] - position[left_vertex];
                bandwidth = @max(bandwidth, difference);
            }
        }
    }
    return (@as(i64, @intCast(bandwidth)) << 24) | rank_word;
}
