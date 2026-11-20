const MAX_N: i64 = 8;
const MAX_INPUT: usize = 10;

export fn maximum_employees_to_be_invited(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 2 or n_value > MAX_N or length != @as(usize, @intCast(n_value + 1))) return -1;
    const n: usize = @intCast(n_value);
    var favorite: [8]usize = undefined;
    var indegree = [_]i64{0} ** 8;
    var chain = [_]i64{1} ** 8;
    var queue: [8]usize = undefined;
    var visited = [_]bool{false} ** 8;
    for (0..n) |i| {
        const target = input[i + 1];
        if (target < 0 or target >= n_value or target == @as(i64, @intCast(i))) return -1;
        favorite[i] = @intCast(target);
        indegree[favorite[i]] += 1;
    }
    var head: usize = 0;
    var tail: usize = 0;
    for (0..n) |i| {
        if (indegree[i] == 0) { queue[tail] = i; tail += 1; }
    }
    while (head < tail) {
        const node = queue[head]; head += 1;
        const target = favorite[node];
        chain[target] = @max(chain[target], chain[node] + 1);
        indegree[target] -= 1;
        if (indegree[target] == 0) { queue[tail] = target; tail += 1; }
    }
    var pair_total: i64 = 0;
    var longest_cycle: i64 = 0;
    for (0..n) |start| {
        if (indegree[start] == 0 or visited[start]) continue;
        var node = start;
        var first: usize = 0;
        var second: usize = 0;
        var cycle_length: i64 = 0;
        while (!visited[node]) {
            visited[node] = true;
            if (cycle_length == 0) first = node else if (cycle_length == 1) second = node;
            cycle_length += 1;
            node = favorite[node];
        }
        if (cycle_length == 2) pair_total += chain[first] + chain[second] else longest_cycle = @max(longest_cycle, cycle_length);
    }
    return @max(pair_total, longest_cycle);
}
