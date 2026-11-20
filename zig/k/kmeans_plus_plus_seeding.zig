const MAX_POINTS: usize = 32;
const MAX_DIMENSION: usize = 4;
const MAX_CENTERS: usize = 8;
const MAX_INPUT_LENGTH: usize = 140;

fn squaredDistance(coordinates: []const i64, dimension: usize,
    row: usize, center: usize) i64 {
    var distance: i64 = 0;
    for (0..dimension) |axis| {
        const difference = coordinates[row * dimension + axis]
            - coordinates[center * dimension + axis];
        distance += difference * difference;
    }
    return distance;
}

fn rowIsSelected(centers: *const [MAX_CENTERS]i64, count: usize, row: i64) bool {
    for (0..count) |index| {
        if (centers[index] == row) return true;
    }
    return false;
}

fn storeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn kmeans_plus_plus_seeding(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const point_count_value = values[0];
    const dimension_value = values[1];
    const center_count_value = values[2];
    const first_row = values[3];
    if (point_count_value < 1 or point_count_value > @as(i64, @intCast(MAX_POINTS))
        or dimension_value < 1 or dimension_value > @as(i64, @intCast(MAX_DIMENSION))
        or center_count_value < 1 or center_count_value > @as(i64, @intCast(MAX_CENTERS))
        or center_count_value > point_count_value
        or first_row < 0 or first_row >= point_count_value) return -1;

    const point_count: usize = @intCast(point_count_value);
    const dimension: usize = @intCast(dimension_value);
    const center_count: usize = @intCast(center_count_value);
    const coordinate_count = point_count * dimension;
    const draw_offset = 4 + coordinate_count;
    if (length != draw_offset + center_count - 1) return -1;

    var coordinates: [MAX_POINTS * MAX_DIMENSION]i64 = @splat(0);
    for (0..coordinate_count) |index| {
        const coordinate = values[4 + index];
        if (coordinate < -16 or coordinate > 16) return -1;
        coordinates[index] = coordinate;
    }

    var centers: [MAX_CENTERS]i64 = @splat(0);
    var nearest: [MAX_POINTS]i64 = @splat(0);
    centers[0] = first_row;
    for (0..point_count) |row| {
        nearest[row] = squaredDistance(coordinates[0..coordinate_count], dimension,
            row, @intCast(first_row));
    }

    for (0..(center_count - 1)) |step| {
        const draw = values[draw_offset + step];
        var total_weight: i64 = 0;
        for (0..point_count) |row| total_weight += nearest[row];

        var chosen: i64 = -1;
        if (total_weight == 0) {
            if (draw != 0) return -1;
            for (0..point_count) |row| {
                if (!rowIsSelected(&centers, step + 1, @intCast(row))) {
                    chosen = @intCast(row);
                    break;
                }
            }
        } else {
            if (draw < 0 or draw >= total_weight) return -1;
            var cumulative: i64 = 0;
            for (0..point_count) |row| {
                cumulative += nearest[row];
                if (cumulative > draw) {
                    chosen = @intCast(row);
                    break;
                }
            }
        }
        if (chosen < 0) return -1;
        centers[step + 1] = chosen;
        for (0..point_count) |row| {
            const distance = squaredDistance(coordinates[0..coordinate_count], dimension,
                row, @intCast(chosen));
            if (distance < nearest[row]) nearest[row] = distance;
        }
    }

    const output_bytes = center_count * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    const bytes = output.?[0..output_bytes];
    for (0..center_count) |index| {
        storeI64Le(bytes, index * 8, centers[index]);
    }
    return @intCast(output_bytes);
}
