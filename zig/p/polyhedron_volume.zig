const MAX_FACES: usize = 32;
const MAX_PARSEABLE_LENGTH: usize = 290;
const SCALE: u64 = 1_000_000;

const Point = struct { x: i64, y: i64, z: i64 };

fn same(a: Point, b: Point) bool { return a.x == b.x and a.y == b.y and a.z == b.z; }
fn subtract(a: Point, b: Point) Point { return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z }; }
fn cross(a: Point, b: Point) Point {
    return .{ .x = a.y * b.z - a.z * b.y, .y = a.z * b.x - a.x * b.z, .z = a.x * b.y - a.y * b.x };
}
fn dot(a: Point, b: Point) i64 { return a.x * b.x + a.y * b.y + a.z * b.z; }
fn edgeMatches(faces: []const Point, face: usize, edge: usize,
                other_face: usize, other_edge: usize, reverse: bool) bool {
    const edge_end = (edge + 1) % 3;
    const other_end = (other_edge + 1) % 3;
    const other_start = if (reverse) other_end else other_edge;
    const other_finish = if (reverse) other_edge else other_end;
    return same(faces[3 * face + edge], faces[3 * other_face + other_start]) and
        same(faces[3 * face + edge_end], faces[3 * other_face + other_finish]);
}
fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn polyhedron_volume(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    const face_count_value = input[0];
    if (face_count_value < 4 or face_count_value > 32) return -1;
    const face_count: usize = @intCast(face_count_value);
    if (length != 1 + 9 * face_count) return -1;

    var faces: [MAX_FACES * 3]Point = undefined;
    for (0..face_count) |face| {
        for (0..3) |corner| {
            const offset = 1 + 9 * face + 3 * corner;
            const point = Point{ .x = input[offset], .y = input[offset + 1], .z = input[offset + 2] };
            if (point.x < -50 or point.x > 50 or point.y < -50 or point.y > 50 or point.z < -50 or point.z > 50) return -1;
            faces[3 * face + corner] = point;
        }
        const ab = subtract(faces[3 * face + 1], faces[3 * face]);
        const ac = subtract(faces[3 * face + 2], faces[3 * face]);
        const normal = cross(ab, ac);
        if (normal.x == 0 and normal.y == 0 and normal.z == 0) return -1;
    }
    for (0..face_count) |face| {
        for (0..3) |edge| {
            var same_count: usize = 0;
            var reverse_count: usize = 0;
            for (0..face_count) |other_face| {
                for (0..3) |other_edge| {
                    if (edgeMatches(faces[0 .. 3 * face_count], face, edge, other_face, other_edge, false)) same_count += 1;
                    if (edgeMatches(faces[0 .. 3 * face_count], face, edge, other_face, other_edge, true)) reverse_count += 1;
                }
            }
            if (same_count != 1 or reverse_count != 1) return -1;
        }
    }

    var determinant_sum: i64 = 0;
    for (0..face_count) |face| {
        determinant_sum += dot(faces[3 * face], cross(faces[3 * face + 1], faces[3 * face + 2]));
    }
    const sign: i64 = if (determinant_sum < 0) -1 else 1;
    const magnitude: u64 = @intCast(if (determinant_sum < 0) -determinant_sum else determinant_sum);
    const scaled = magnitude * SCALE;
    var quotient = scaled / 6;
    if (2 * (scaled % 6) >= 6) quotient += 1;
    const result = sign * @as(i64, @intCast(quotient));
    if (output_opt == null or capacity < 8) return -2;
    storeI64Le(output_opt.?, result);
    return 8;
}
