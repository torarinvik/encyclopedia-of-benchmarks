/// Return the leftmost longest ASCII alphanumeric palindrome with Manacher's algorithm.
fn isAsciiAlphanumeric(value: i64) bool {
    return (value >= '0' and value <= '9') or
        (value >= 'A' and value <= 'Z') or
        (value >= 'a' and value <= 'z');
}

fn transformedEqual(values: [*]const i64, left: usize, right: usize) bool {
    if ((left & 1) != (right & 1)) return false;
    return (left & 1) == 0 or values[left / 2] == values[right / 2];
}

export fn manacher(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 1000) return -1;
    for (0..length) |index| {
        if (!isAsciiAlphanumeric(values[index])) return -1;
    }

    var radii: [2001]usize = @splat(0);
    const transformed_length = 2 * length + 1;
    var center: usize = 0;
    var right: usize = 0;
    var best_center: usize = 0;
    var best_radius: usize = 0;
    for (0..transformed_length) |index| {
        var radius: usize = 0;
        if (index < right) {
            const mirror = 2 * center - index;
            radius = @min(radii[mirror], right - index);
        }
        while (radius < index and radius < transformed_length - 1 - index and
            transformedEqual(values, index - radius - 1, index + radius + 1))
        {
            radius += 1;
        }
        radii[index] = radius;
        if (index + radius > right) {
            center = index;
            right = index + radius;
        }
        if (radius > best_radius) {
            best_center = index;
            best_radius = radius;
        }
    }

    const best_start = (best_center - best_radius) / 2;
    if (output_capacity < best_radius) return -2;
    for (0..best_radius) |index| {
        output[index] = @intCast(values[best_start + index]);
    }
    return @intCast(best_radius);
}
