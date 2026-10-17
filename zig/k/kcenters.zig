const MAX_POINTS: usize = 8;
const MAX_POINTS_I64: i64 = 8;
const MAX_DISTANCE: i64 = 1_000_000;
const JAVA_INT_MAX: i64 = 2_147_483_647;
const MAX_INPUT_LENGTH: usize = 2 + MAX_POINTS * MAX_POINTS;

export fn kcenters(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const point_count = values[0];
    const center_count = values[1];
    if (point_count < 1 or point_count > MAX_POINTS_I64 or center_count < 1 or center_count > point_count or
        length != @as(usize, @intCast(2 + point_count * point_count))) return -1;
    const count: usize = @intCast(point_count);
    for (0..count) |row| {
        for (0..count) |column| {
            const distance = values[2 + row * count + column];
            if (distance < 0 or distance > MAX_DISTANCE or (row == column and distance != 0)) return -1;
            if (distance != values[2 + column * count + row]) return -1;
        }
    }

    var selected = [_]bool{false} ** MAX_POINTS;
    var max_distance = [_]i64{JAVA_INT_MAX} ** MAX_POINTS;
    selected[0] = true;
    for (1..count) |point| {
        const distance = values[2 + point];
        max_distance[point] = @min(max_distance[point], distance);
    }
    for (1..@as(usize, @intCast(center_count))) |_| {
        var farthest: ?usize = null;
        for (0..count) |point| {
            if (!selected[point] and (farthest == null or max_distance[point] > max_distance[farthest.?])) {
                farthest = point;
            }
        }
        const center = farthest.?;
        selected[center] = true;
        for (0..count) |point| {
            const distance = values[2 + center * count + point];
            max_distance[point] = @min(max_distance[point], distance);
        }
    }
    var result: i64 = 0;
    for (0..count) |point| result = @max(result, max_distance[point]);
    return result;
}
