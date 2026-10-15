/// Return whether every room is reachable from room zero.
export fn keys_and_rooms(values: [*]const i64, length: usize) i64 {
    const max_rooms = 1000;
    const max_input_length = 100001;
    if (length < 3 or length > max_input_length) return -1;
    if (values[0] < 2 or values[0] > max_rooms) return -1;
    const room_count: usize = @intCast(values[0]);
    var starts: [max_rooms]usize = @splat(0);
    var degrees: [max_rooms]usize = @splat(0);
    var cursor: usize = 1;

    for (0..room_count) |room| {
        if (cursor >= length) return -1;
        const count_value = values[cursor];
        cursor += 1;
        if (count_value < 0 or count_value > room_count) return -1;
        const degree: usize = @intCast(count_value);
        if (degree > length - cursor) return -1;
        starts[room] = cursor;
        degrees[room] = degree;
        for (0..degree) |edge| {
            const key = values[cursor + edge];
            if (key < 0 or key >= room_count) return -1;
        }
        cursor += degree;
    }
    if (cursor != length) return -1;

    var visited: [max_rooms]bool = @splat(false);
    var stack: [max_rooms]usize = @splat(0);
    var stack_size: usize = 1;
    var reached: usize = 0;
    stack[0] = 0;
    visited[0] = true;
    while (stack_size > 0) {
        stack_size -= 1;
        const room = stack[stack_size];
        reached += 1;
        for (0..degrees[room]) |edge| {
            const key: usize = @intCast(values[starts[room] + edge]);
            if (!visited[key]) {
                visited[key] = true;
                stack[stack_size] = key;
                stack_size += 1;
            }
        }
    }
    return if (reached == room_count) 1 else 0;
}
