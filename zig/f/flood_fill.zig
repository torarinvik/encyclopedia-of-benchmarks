const MAX_SIDE: usize = 32;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;

fn putI64(output: [*c]u8, index: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[index * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn flood_fill(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (length < 6 or length > 6 + MAX_CELLS) return -1;
    const width_value = input[0];
    const height_value = input[1];
    const start_x_value = input[2];
    const start_y_value = input[3];
    const new_color = input[4];
    const target_color = input[5];
    if (width_value < 1 or width_value > MAX_SIDE or height_value < 1 or height_value > MAX_SIDE
        or new_color < -2147483648 or new_color > 2147483647
        or target_color < -2147483648 or target_color > 2147483647 or new_color == target_color) return -1;
    const width: usize = @intCast(width_value);
    const height: usize = @intCast(height_value);
    if (length != 6 + width * height or start_x_value < 0 or start_x_value >= width_value
        or start_y_value < 0 or start_y_value >= height_value) return -1;
    const cells = width * height;
    var image: [MAX_CELLS]i64 = @splat(0);
    for (0..cells) |index| {
        image[index] = input[6 + index];
        if (image[index] < -2147483648 or image[index] > 2147483647) return -1;
    }
    const start: usize = @intCast(start_x_value * height_value + start_y_value);
    if (image[start] == target_color) {
        var stack: [MAX_CELLS]usize = @splat(0);
        var top: usize = 0;
        image[start] = new_color;
        stack[top] = start;
        top += 1;
        while (top > 0) {
            top -= 1;
            const index = stack[top];
            const x: i64 = @intCast(index / height);
            const y: i64 = @intCast(index % height);
            var dx: i64 = -1;
            while (dx <= 1) : (dx += 1) {
                var dy: i64 = -1;
                while (dy <= 1) : (dy += 1) {
                    if (dx == 0 and dy == 0) continue;
                    const next_x = x + dx;
                    const next_y = y + dy;
                    if (next_x < 0 or next_x >= width_value or next_y < 0 or next_y >= height_value) continue;
                    const next: usize = @intCast(next_x * height_value + next_y);
                    if (image[next] == target_color) {
                        image[next] = new_color;
                        stack[top] = next;
                        top += 1;
                    }
                }
            }
        }
    }
    const required = cells * 8;
    if (capacity < required) return -2;
    for (0..cells) |index| putI64(output, index, image[index]);
    return @intCast(required);
}
