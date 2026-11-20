export fn same_value_teleport_bfs(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 65) return -2;
    if (input[0] < 1 or input[0] > 64 or length != @as(usize, @intCast(input[0])) + 1) return -2;
    const n: usize = @intCast(input[0]);
    for (0..n) |i| if (input[i + 1] < -64 or input[i + 1] > 64) return -2;
    if (n == 1) return 0;

    var first: [129]i32 = @splat(-1);
    var next: [64]i32 = @splat(-1);
    var queue: [64]i32 = @splat(0);
    var distance: [64]i32 = @splat(-1);
    for (0..n) |i| {
        const slot: usize = @intCast(input[i + 1] + 64);
        next[i] = first[slot];
        first[slot] = @intCast(i);
    }
    var front: usize = 0;
    var back: usize = 1;
    queue[0] = 0;
    distance[0] = 0;
    while (front < back) {
        const index: usize = @intCast(queue[front]);
        front += 1;
        if (index == n - 1) return @as(i64, distance[index]);
        if (index > 0 and distance[index - 1] < 0) {
            distance[index - 1] = distance[index] + 1;
            queue[back] = @intCast(index - 1);
            back += 1;
        }
        if (index + 1 < n and distance[index + 1] < 0) {
            distance[index + 1] = distance[index] + 1;
            queue[back] = @intCast(index + 1);
            back += 1;
        }
        const slot: usize = @intCast(input[index + 1] + 64);
        var member = first[slot];
        if (member >= 0) {
            first[slot] = -1;
            while (member >= 0) {
                const member_index: usize = @intCast(member);
                if (distance[member_index] < 0) {
                    distance[member_index] = distance[index] + 1;
                    queue[back] = member;
                    back += 1;
                }
                member = next[member_index];
            }
        }
    }
    return @as(i64, distance[n - 1]);
}
