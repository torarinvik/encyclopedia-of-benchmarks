/// Deterministic closest pair using x-ranked divide-and-conquer and y strips.
const MAX_POINTS: usize = 1024;

const Point = struct { x: i64, y: i64 };
const PairResult = struct {
    valid: bool = false,
    distance_squared: u64 = 0,
    first: usize = 0,
    second: usize = 0,
};

fn before(left: usize, right: usize, points: []const Point, by_y: bool) bool {
    if (by_y) {
        if (points[left].y != points[right].y) return points[left].y < points[right].y;
        if (points[left].x != points[right].x) return points[left].x < points[right].x;
    } else {
        if (points[left].x != points[right].x) return points[left].x < points[right].x;
        if (points[left].y != points[right].y) return points[left].y < points[right].y;
    }
    return left < right;
}

fn sortIndices(indices: []usize, scratch: []usize, begin: usize, end: usize,
    points: []const Point, by_y: bool) void {
    if (end - begin < 2) return;
    const middle = begin + (end - begin) / 2;
    sortIndices(indices, scratch, begin, middle, points, by_y);
    sortIndices(indices, scratch, middle, end, points, by_y);
    var left = begin;
    var right = middle;
    var out = begin;
    while (left < middle and right < end) {
        if (before(indices[right], indices[left], points, by_y)) {
            scratch[out] = indices[right];
            right += 1;
        } else {
            scratch[out] = indices[left];
            left += 1;
        }
        out += 1;
    }
    while (left < middle) : (left += 1) {
        scratch[out] = indices[left];
        out += 1;
    }
    while (right < end) : (right += 1) {
        scratch[out] = indices[right];
        out += 1;
    }
    @memcpy(indices[begin..end], scratch[begin..end]);
}

fn squaredDistance(left: usize, right: usize, points: []const Point) u64 {
    const dx = points[left].x - points[right].x;
    const dy = points[left].y - points[right].y;
    return @as(u64, @intCast(dx * dx)) + @as(u64, @intCast(dy * dy));
}

fn choose(left: PairResult, right: PairResult) PairResult {
    if (!left.valid) return right;
    if (!right.valid) return left;
    if (left.distance_squared < right.distance_squared) return left;
    if (right.distance_squared < left.distance_squared) return right;
    if (left.first < right.first or (left.first == right.first and left.second <= right.second)) return left;
    return right;
}

fn candidate(left: usize, right: usize, points: []const Point) PairResult {
    const first = @min(left, right);
    const second = @max(left, right);
    return .{
        .valid = true,
        .distance_squared = squaredDistance(first, second, points),
        .first = first,
        .second = second,
    };
}

fn search(x_order: []const usize, begin: usize, end: usize, y_order: []const usize,
    rank: []const usize, points: []const Point) PairResult {
    const count = end - begin;
    if (count <= 3) {
        var best = PairResult{};
        var i = begin;
        while (i < end) : (i += 1) {
            var j = i + 1;
            while (j < end) : (j += 1) best = choose(best, candidate(x_order[i], x_order[j], points));
        }
        return best;
    }

    const middle = begin + count / 2;
    var y_left: [MAX_POINTS]usize = undefined;
    var y_right: [MAX_POINTS]usize = undefined;
    var left_count: usize = 0;
    var right_count: usize = 0;
    for (y_order) |point| {
        if (rank[point] < middle) {
            y_left[left_count] = point;
            left_count += 1;
        } else {
            y_right[right_count] = point;
            right_count += 1;
        }
    }
    var best = choose(
        search(x_order, begin, middle, y_left[0..left_count], rank, points),
        search(x_order, middle, end, y_right[0..right_count], rank, points),
    );

    var strip: [MAX_POINTS]usize = undefined;
    var strip_count: usize = 0;
    const middle_x = points[x_order[middle]].x;
    for (y_order) |point| {
        const dx = points[point].x - middle_x;
        if (@as(u64, @intCast(dx * dx)) <= best.distance_squared) {
            strip[strip_count] = point;
            strip_count += 1;
        }
    }
    var i: usize = 0;
    while (i < strip_count) : (i += 1) {
        var j = i + 1;
        while (j < strip_count) : (j += 1) {
            const dy = points[strip[j]].y - points[strip[i]].y;
            if (@as(u64, @intCast(dy * dy)) > best.distance_squared) break;
            best = choose(best, candidate(strip[i], strip[j], points));
        }
    }
    return best;
}

fn writePair(output: [*c]u8, pair: PairResult) void {
    const first: u32 = @intCast(pair.first);
    const second: u32 = @intCast(pair.second);
    for (0..4) |byte| {
        output[byte] = @truncate(first >> @intCast(8 * byte));
        output[4 + byte] = @truncate(second >> @intCast(8 * byte));
    }
}

export fn closest_pair_divide_and_conquer(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length > 2 * MAX_POINTS or length % 2 != 0 or (length != 0 and values == null)) return -1;
    const point_count = length / 2;
    var points: [MAX_POINTS]Point = undefined;
    var x_order: [MAX_POINTS]usize = undefined;
    var y_order: [MAX_POINTS]usize = undefined;
    var rank: [MAX_POINTS]usize = undefined;
    var scratch: [MAX_POINTS]usize = undefined;
    for (0..point_count) |index| {
        const x = values[2 * index];
        const y = values[2 * index + 1];
        if (x < -1_000_000_000 or x > 1_000_000_000 or
            y < -1_000_000_000 or y > 1_000_000_000) return -1;
        points[index] = .{ .x = x, .y = y };
        x_order[index] = index;
        y_order[index] = index;
    }
    if (point_count < 2) return 0;
    const points_slice = points[0..point_count];
    const x_slice = x_order[0..point_count];
    const y_slice = y_order[0..point_count];
    const scratch_slice = scratch[0..point_count];
    sortIndices(x_slice, scratch_slice, 0, point_count, points_slice, false);
    for (x_slice, 0..) |point, position| rank[point] = position;
    const rank_slice = rank[0..point_count];

    var duplicate = PairResult{};
    var begin: usize = 0;
    while (begin < point_count) {
        var end = begin + 1;
        const anchor = x_slice[begin];
        while (end < point_count and points[x_slice[end]].x == points[anchor].x and
            points[x_slice[end]].y == points[anchor].y) : (end += 1) {}
        if (end - begin > 1) {
            var first = MAX_POINTS;
            var second = MAX_POINTS;
            for (x_slice[begin..end]) |id| {
                if (id < first) {
                    second = first;
                    first = id;
                } else if (id < second) {
                    second = id;
                }
            }
            duplicate = choose(duplicate, .{
                .valid = true,
                .distance_squared = 0,
                .first = first,
                .second = second,
            });
        }
        begin = end;
    }
    if (duplicate.valid) {
        if (output == null or output_capacity < 8) return -2;
        writePair(output, duplicate);
        return 2;
    }

    sortIndices(y_slice, scratch_slice, 0, point_count, points_slice, true);
    const best = search(x_slice, 0, point_count, y_slice, rank_slice, points_slice);
    if (!best.valid) return -1;
    if (output == null or output_capacity < 8) return -2;
    writePair(output, best);
    return 2;
}
