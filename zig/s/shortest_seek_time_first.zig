const MAX_REQUESTS: usize = 64;

export fn shortest_seek_time_first(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > 2 + MAX_REQUESTS) return -1;
    const initial_track = values[0];
    const request_count = values[1];
    if (initial_track < 0 or initial_track > 255 or request_count < 0 or
        request_count > @as(i64, @intCast(MAX_REQUESTS))
        or length != 2 + @as(usize, @intCast(request_count))) return -1;
    for (0..@intCast(request_count)) |i| {
        const request = values[2 + i];
        if (request < 0 or request > 255) return -1;
    }
    if (output == null or output_capacity < @as(usize, @intCast(request_count))) return -2;

    var serviced: [MAX_REQUESTS]bool = @splat(false);
    var current = initial_track;
    for (0..@intCast(request_count)) |step| {
        var best: usize = MAX_REQUESTS;
        var best_distance: i64 = 256;
        for (0..@intCast(request_count)) |i| {
            if (serviced[i]) continue;
            var distance = current - values[2 + i];
            if (distance < 0) distance = -distance;
            if (distance < best_distance) { best = i; best_distance = distance; }
        }
        const selected = values[2 + best];
        output[step] = @intCast(selected);
        serviced[best] = true;
        current = selected;
    }
    return request_count;
}
