const MAX_LENGTH: usize = 1024;

export fn jump_game_ii(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > @as(i64, @intCast(length))) return -1;
    }
    if (length == 1) return 0;
    var queue: [MAX_LENGTH]usize = undefined;
    var distance: [MAX_LENGTH]usize = undefined;
    var visited: [MAX_LENGTH]bool = undefined;
    for (0..length) |index| {
        distance[index] = 0;
        visited[index] = false;
    }
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = 0;
    visited[0] = true;
    while (head < tail) {
        const cell = queue[head];
        head += 1;
        const farthest = cell + @as(usize, @intCast(values[cell]));
        if (farthest >= length - 1) return @intCast(distance[cell] + 1);
        var next = cell + 1;
        while (next <= farthest) : (next += 1) {
            if (!visited[next]) {
                visited[next] = true;
                distance[next] = distance[cell] + 1;
                queue[tail] = next;
                tail += 1;
            }
        }
    }
    return -1;
}
