// Adapted from Trekhleb's seam-carving explanation. Copyright (c) 2018
// Oleksii Trekhleb; MIT License, see benchmarks/s/seam_carving/LICENSE.txt.
export fn seam_carving(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 39) return -1;
    const input = input_opt.?;
    const width_value = input[0];
    const height_value = input[1];
    if (width_value < 2 or width_value > 6 or height_value < 1 or height_value > 6) return -1;
    const width: usize = @intCast(width_value);
    const height: usize = @intCast(height_value);
    if (length != 2 + width * height) return -1;
    for (0..width * height) |index| {
        if (input[2 + index] < 0 or input[2 + index] > 255) return -1;
    }

    var energy = [_][6]f64{[_]f64{0.0} ** 6} ** 6;
    var cumulative = [_][6]f64{[_]f64{0.0} ** 6} ** 6;
    var previous_x = [_][6]usize{[_]usize{0} ** 6} ** 6;
    var seam_x = [_]usize{0} ** 6;
    for (0..height) |y| {
        const row = y * width;
        for (0..width) |x| {
            const middle: f64 = @floatFromInt(input[2 + row + x]);
            var left_energy: f64 = 0.0;
            var right_energy: f64 = 0.0;
            if (x > 0) {
                const difference = @as(f64, @floatFromInt(input[2 + row + x - 1])) - middle;
                left_energy = difference * difference + difference * difference + difference * difference;
            }
            if (x + 1 < width) {
                const difference = @as(f64, @floatFromInt(input[2 + row + x + 1])) - middle;
                right_energy = difference * difference + difference * difference + difference * difference;
            }
            energy[y][x] = @sqrt(left_energy + right_energy);
        }
    }
    for (0..width) |x| cumulative[0][x] = energy[0][x];
    for (1..height) |y| {
        for (0..width) |x| {
            var minimum: f64 = 1.0e300;
            var best_x = x;
            const start = if (x == 0) 0 else x - 1;
            const end = if (x + 1 < width) x + 1 else width - 1;
            var candidate = start;
            while (candidate <= end) : (candidate += 1) {
                if (cumulative[y - 1][candidate] < minimum) {
                    minimum = cumulative[y - 1][candidate];
                    best_x = candidate;
                }
            }
            cumulative[y][x] = minimum + energy[y][x];
            previous_x[y][x] = best_x;
        }
    }
    var last_x: usize = 0;
    var minimum = cumulative[height - 1][0];
    for (1..width) |x| {
        if (cumulative[height - 1][x] < minimum) {
            minimum = cumulative[height - 1][x];
            last_x = x;
        }
    }
    seam_x[height - 1] = last_x;
    var y = height - 1;
    while (y > 0) : (y -= 1) seam_x[y - 1] = previous_x[y][seam_x[y]];

    const needed = height * (width - 1);
    const output = output_opt orelse return -2;
    if (output_capacity < needed) return -2;
    var staged = [_]u8{0} ** 30;
    var position: usize = 0;
    for (0..height) |row_index| {
        for (0..width) |x| {
            if (x != seam_x[row_index]) {
                staged[position] = @intCast(input[2 + row_index * width + x]);
                position += 1;
            }
        }
    }
    @memcpy(output[0..needed], staged[0..needed]);
    return @intCast(needed);
}
