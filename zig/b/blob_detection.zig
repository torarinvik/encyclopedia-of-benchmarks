const MAX_SIDE: usize = 128;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;
const MAX_INPUT_LENGTH: usize = 3 + 3 * MAX_CELLS;

fn isTargetColor(red: i64, green: i64, blue: i64, profile: i64) bool {
    const maximum = @max(red, @max(green, blue));
    const minimum = @min(red, @min(green, blue));
    const delta = maximum - minimum;
    const hue_minimum: i64 = if (profile == 0) 379 else 398;
    const hue_maximum: i64 = if (profile == 0) 496 else 498;
    const saturation_minimum: i64 = if (profile == 0) 436 else 355;
    if (maximum == 0 or delta == 0 or 1000 * delta < saturation_minimum * maximum) return false;
    var hue_numerator: i64 = undefined;
    if (maximum == red) {
        hue_numerator = @rem(green - blue, 6 * delta);
        if (hue_numerator < 0) hue_numerator += 6 * delta;
    } else if (maximum == green) {
        hue_numerator = 2 * delta + blue - red;
    } else {
        hue_numerator = 4 * delta + red - green;
    }
    return hue_minimum * 6 * delta <= 1000 * hue_numerator and
        1000 * hue_numerator <= hue_maximum * 6 * delta;
}

export fn blob_detection(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const height_value = input[0];
    const width_value = input[1];
    const profile = input[2];
    if (height_value < 1 or height_value > MAX_SIDE or
        width_value < 1 or width_value > MAX_SIDE) return -1;
    const height: usize = @intCast(height_value);
    const width: usize = @intCast(width_value);
    const cells = height * width;
    if ((profile != 0 and profile != 1) or length != 3 + 3 * cells) return -1;
    for (0..3 * cells) |channel| {
        if (input[3 + channel] < 0 or input[3 + channel] > 255) return -1;
    }

    var mask: [MAX_CELLS]bool = @splat(false);
    var eroded: [MAX_CELLS]bool = @splat(false);
    var opened: [MAX_CELLS]bool = @splat(false);
    var visited: [MAX_CELLS]bool = @splat(false);
    var queue: [MAX_CELLS]usize = undefined;
    for (0..cells) |index| {
        mask[index] = isTargetColor(input[3 + 3 * index], input[4 + 3 * index],
                                    input[5 + 3 * index], profile);
    }

    for (0..height) |row| {
        for (0..width) |column| {
            var keep = true;
            var dy: i64 = -3;
            while (dy <= 3 and keep) : (dy += 1) {
                var dx: i64 = -3;
                while (dx <= 3) : (dx += 1) {
                    if (dx * dx + dy * dy > 9) continue;
                    const y = @as(i64, @intCast(row)) + dy;
                    const x = @as(i64, @intCast(column)) + dx;
                    if (y >= 0 and y < height_value and x >= 0 and x < width_value and
                        !mask[@as(usize, @intCast(y)) * width + @as(usize, @intCast(x))]) {
                        keep = false;
                        break;
                    }
                }
            }
            eroded[row * width + column] = keep;
        }
    }

    for (0..height) |row| {
        for (0..width) |column| {
            var set = false;
            var dy: i64 = -3;
            while (dy <= 3 and !set) : (dy += 1) {
                var dx: i64 = -3;
                while (dx <= 3) : (dx += 1) {
                    if (dx * dx + dy * dy > 9) continue;
                    const y = @as(i64, @intCast(row)) + dy;
                    const x = @as(i64, @intCast(column)) + dx;
                    if (y >= 0 and y < height_value and x >= 0 and x < width_value and
                        eroded[@as(usize, @intCast(y)) * width + @as(usize, @intCast(x))]) {
                        set = true;
                        break;
                    }
                }
            }
            opened[row * width + column] = set;
        }
    }

    var object_count: i64 = 0;
    for (0..cells) |start| {
        if (!opened[start] or visited[start]) continue;
        var head: usize = 0;
        var tail: usize = 0;
        var area: usize = 0;
        visited[start] = true;
        queue[tail] = start;
        tail += 1;
        while (head < tail) {
            const index = queue[head];
            head += 1;
            area += 1;
            const row: i64 = @intCast(index / width);
            const column: i64 = @intCast(index % width);
            var dy: i64 = -1;
            while (dy <= 1) : (dy += 1) {
                var dx: i64 = -1;
                while (dx <= 1) : (dx += 1) {
                    if (dx == 0 and dy == 0) continue;
                    const y = row + dy;
                    const x = column + dx;
                    if (y < 0 or y >= height_value or x < 0 or x >= width_value) continue;
                    const neighbor = @as(usize, @intCast(y)) * width + @as(usize, @intCast(x));
                    if (opened[neighbor] and !visited[neighbor]) {
                        visited[neighbor] = true;
                        queue[tail] = neighbor;
                        tail += 1;
                    }
                }
            }
        }
        if (area >= 200 and area <= 5000) {
            object_count += 1;
            if (object_count == 50) return object_count;
        }
    }
    return object_count;
}
