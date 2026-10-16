const MAX_REQUESTS: usize = 64;
const MAX_CYLINDER_COUNT: i64 = 128;

fn sortAscending(items: *[MAX_REQUESTS]i64, count: usize) void {
    if (count < 2) return;
    for (1..count) |index| {
        const value = items[index];
        var position = index;
        while (position > 0 and items[position - 1] > value) {
            items[position] = items[position - 1];
            position -= 1;
        }
        items[position] = value;
    }
}

export fn circular_scan_scheduling(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 4 or length > 4 + MAX_REQUESTS) return -1;
    const max_cylinder = values[0];
    const start = values[1];
    const moving_up = values[2];
    const request_count = values[3];
    if (max_cylinder < 1 or max_cylinder > MAX_CYLINDER_COUNT or start < 0 or start >= max_cylinder
        or (moving_up != 0 and moving_up != 1) or request_count < 0 or request_count > MAX_REQUESTS
        or length != 4 + @as(usize, @intCast(request_count))) return -1;

    var up: [MAX_REQUESTS]i64 = @splat(0);
    var down: [MAX_REQUESTS]i64 = @splat(0);
    var up_count: usize = 0;
    var down_count: usize = 0;
    for (0..@intCast(request_count)) |index| {
        const request = values[4 + index];
        if (request < -128 or request > 127) return -1;
        if (moving_up == 1) {
            if (request >= start and request < max_cylinder) {
                up[up_count] = request;
                up_count += 1;
            } else {
                if (request < start) {
                    down[down_count] = request;
                    down_count += 1;
                }
            }
        } else if (request <= start) {
            down[down_count] = request;
            down_count += 1;
        } else {
            up[up_count] = request;
            up_count += 1;
        }
    }
    sortAscending(&up, up_count);
    sortAscending(&down, down_count);

    const output_count = up_count + down_count;
    if (output_capacity < output_count or (output_count > 0 and output == null)) return -2;
    var position: usize = 0;
    if (moving_up == 1) {
        for (0..up_count) |index| {
            output[position] = @intCast(@mod(up[index] + 256, 256));
            position += 1;
        }
        for (0..down_count) |index| {
            output[position] = @intCast(@mod(down[index] + 256, 256));
            position += 1;
        }
    } else {
        var index = down_count;
        while (index > 0) {
            index -= 1;
            output[position] = @intCast(@mod(down[index] + 256, 256));
            position += 1;
        }
        index = up_count;
        while (index > 0) {
            index -= 1;
            output[position] = @intCast(@mod(up[index] + 256, 256));
            position += 1;
        }
    }
    return @intCast(output_count);
}
