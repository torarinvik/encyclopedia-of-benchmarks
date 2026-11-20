const std = @import("std");

const MAX_POINTS: usize = 32;
const MAX_INPUT_VALUES: usize = 66;
const MAX_COORDINATE: i64 = 1000;

const Point = struct { x: i64, y: i64 };
const Slope = struct { dy: i64, dx: i64 };
const Bridge = struct { left: usize, right: usize };

fn compareSlope(a: Slope, b: Slope) i8 {
    const left = a.dy * b.dx;
    const right = b.dy * a.dx;
    return if (left < right) -1 else if (left > right) 1 else 0;
}

fn sortIdsByX(ids: []usize, points: []const Point) void {
    var index: usize = 1;
    while (index < ids.len) : (index += 1) {
        const value = ids[index];
        var cursor = index;
        while (cursor > 0 and points[ids[cursor - 1]].x > points[value].x) {
            ids[cursor] = ids[cursor - 1];
            cursor -= 1;
        }
        ids[cursor] = value;
    }
}

fn selectIdByX(ids: []usize, rank: usize, points: []const Point) usize {
    if (ids.len <= 5) {
        sortIdsByX(ids, points);
        return ids[rank];
    }
    var medians: [MAX_POINTS]usize = undefined;
    var median_count: usize = 0;
    var start: usize = 0;
    while (start < ids.len) {
        const group = @min(5, ids.len - start);
        sortIdsByX(ids[start .. start + group], points);
        medians[median_count] = ids[start + (group - 1) / 2];
        median_count += 1;
        start += group;
    }
    const pivot = selectIdByX(medians[0..median_count], (median_count - 1) / 2, points);
    var lower: usize = 0;
    var cursor: usize = 0;
    var upper = ids.len;
    while (cursor < upper) {
        if (points[ids[cursor]].x < points[pivot].x) {
            std.mem.swap(usize, &ids[lower], &ids[cursor]);
            lower += 1;
            cursor += 1;
        } else if (points[ids[cursor]].x > points[pivot].x) {
            upper -= 1;
            std.mem.swap(usize, &ids[upper], &ids[cursor]);
        } else {
            cursor += 1;
        }
    }
    if (rank < lower) return selectIdByX(ids[0..lower], rank, points);
    if (rank < upper) return pivot;
    return selectIdByX(ids[upper..], rank - upper, points);
}

fn sortSlopes(values: []Slope) void {
    var index: usize = 1;
    while (index < values.len) : (index += 1) {
        const value = values[index];
        var cursor = index;
        while (cursor > 0 and compareSlope(values[cursor - 1], value) > 0) {
            values[cursor] = values[cursor - 1];
            cursor -= 1;
        }
        values[cursor] = value;
    }
}

fn selectSlope(values: []Slope, rank: usize) Slope {
    if (values.len <= 5) {
        sortSlopes(values);
        return values[rank];
    }
    var medians: [MAX_POINTS]Slope = undefined;
    var median_count: usize = 0;
    var start: usize = 0;
    while (start < values.len) {
        const group = @min(5, values.len - start);
        sortSlopes(values[start .. start + group]);
        medians[median_count] = values[start + (group - 1) / 2];
        median_count += 1;
        start += group;
    }
    const pivot = selectSlope(medians[0..median_count], (median_count - 1) / 2);
    var lower: usize = 0;
    var cursor: usize = 0;
    var upper = values.len;
    while (cursor < upper) {
        const order = compareSlope(values[cursor], pivot);
        if (order < 0) {
            std.mem.swap(Slope, &values[lower], &values[cursor]);
            lower += 1;
            cursor += 1;
        } else if (order > 0) {
            upper -= 1;
            std.mem.swap(Slope, &values[upper], &values[cursor]);
        } else {
            cursor += 1;
        }
    }
    if (rank < lower) return selectSlope(values[0..lower], rank);
    if (rank < upper) return pivot;
    return selectSlope(values[upper..], rank - upper);
}

fn pairSlope(first: usize, second: usize, points: []const Point) Slope {
    const left = if (points[first].x < points[second].x) first else second;
    const right = if (left == first) second else first;
    return .{ .dy = points[right].y - points[left].y,
              .dx = points[right].x - points[left].x };
}

fn upperBridge(points: []const Point, candidates: []usize, separator: i64) Bridge {
    var count = candidates.len;
    while (count > 2) {
        const pair_count = count / 2;
        var slopes: [MAX_POINTS]Slope = undefined;
        for (0..pair_count) |pair|
            slopes[pair] = pairSlope(candidates[2 * pair], candidates[2 * pair + 1], points);
        const rank = (pair_count - 1) / 2;
        const median = selectSlope(slopes[0..pair_count], rank);
        var support: i64 = -5_000_000;
        for (candidates[0..count]) |id| {
            const p = points[id];
            const score = p.y * median.dx - median.dy * p.x;
            if (score > support) support = score;
        }
        var left: usize = MAX_POINTS;
        var right: usize = MAX_POINTS;
        for (candidates[0..count]) |id| {
            const p = points[id];
            if (p.y * median.dx - median.dy * p.x == support) {
                if (left == MAX_POINTS or p.x < points[left].x) left = id;
                if (right == MAX_POINTS or p.x > points[right].x) right = id;
            }
        }
        if (points[left].x <= separator and separator < points[right].x)
            return .{ .left = left, .right = right };

        const support_is_left = points[right].x <= separator;
        var next: [MAX_POINTS]usize = undefined;
        var next_count: usize = 0;
        for (0..pair_count) |pair| {
            const first = candidates[2 * pair];
            const second = candidates[2 * pair + 1];
            const order = compareSlope(pairSlope(first, second, points), median);
            var keep_first = false;
            var keep_second = false;
            if (support_is_left) {
                keep_first = order < 0;
                keep_second = order < 0;
                if (order >= 0) {
                    keep_first = points[first].x > points[second].x;
                    keep_second = points[second].x > points[first].x;
                }
            } else {
                keep_first = order > 0;
                keep_second = order > 0;
                if (order <= 0) {
                    keep_first = points[first].x < points[second].x;
                    keep_second = points[second].x < points[first].x;
                }
            }
            if (keep_first) { next[next_count] = first; next_count += 1; }
            if (keep_second) { next[next_count] = second; next_count += 1; }
        }
        if (count % 2 == 1) { next[next_count] = candidates[count - 1]; next_count += 1; }
        @memcpy(candidates[0..next_count], next[0..next_count]);
        count = next_count;
    }
    return if (points[candidates[0]].x < points[candidates[1]].x)
        .{ .left = candidates[0], .right = candidates[1] }
    else
        .{ .left = candidates[1], .right = candidates[0] };
}

fn appendUnique(chain: []usize, chain_count: *usize, point: usize) void {
    if (chain_count.* == 0 or chain[chain_count.* - 1] != point) {
        chain[chain_count.*] = point;
        chain_count.* += 1;
    }
}

fn connectUpper(points: []const Point, candidates: []const usize,
    left: usize, right: usize, chain: []usize, chain_count: *usize) void {
    if (left == right) {
        appendUnique(chain, chain_count, left);
        return;
    }
    var ids: [MAX_POINTS]usize = undefined;
    @memcpy(ids[0..candidates.len], candidates);
    const separator = points[selectIdByX(ids[0..candidates.len], (candidates.len - 1) / 2, points)].x;
    var bridge_candidates: [MAX_POINTS]usize = undefined;
    @memcpy(bridge_candidates[0..candidates.len], candidates);
    const bridge = upperBridge(points, bridge_candidates[0..candidates.len], separator);
    var left_set: [MAX_POINTS]usize = undefined;
    var right_set: [MAX_POINTS]usize = undefined;
    var left_count: usize = 0;
    var right_count: usize = 0;
    for (candidates) |id| {
        if (points[id].x <= points[bridge.left].x) { left_set[left_count] = id; left_count += 1; }
        if (points[id].x >= points[bridge.right].x) { right_set[right_count] = id; right_count += 1; }
    }
    connectUpper(points, left_set[0..left_count], left, bridge.left, chain, chain_count);
    appendUnique(chain, chain_count, bridge.right);
    connectUpper(points, right_set[0..right_count], bridge.right, right, chain, chain_count);
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn kirkpatrick_seidel_convex_hull(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 3 or values[0] > MAX_POINTS) return -1;
    const count: usize = @intCast(values[0]);
    if (length != 1 + 2 * count) return -1;
    var original: [MAX_POINTS]Point = undefined;
    var upper_points: [MAX_POINTS]Point = undefined;
    var lower_points: [MAX_POINTS]Point = undefined;
    var seen_x = [_]bool{false} ** (2 * @as(usize, @intCast(MAX_COORDINATE)) + 1);
    for (0..count) |index| {
        const x = values[1 + 2 * index];
        const y = values[2 + 2 * index];
        if (x < -MAX_COORDINATE or x > MAX_COORDINATE or
            y < -MAX_COORDINATE or y > MAX_COORDINATE) return -1;
        const slot: usize = @intCast(x + MAX_COORDINATE);
        if (seen_x[slot]) return -1;
        seen_x[slot] = true;
        original[index] = .{ .x = x, .y = y };
        upper_points[index] = .{ .x = x, .y = y };
        lower_points[index] = .{ .x = x, .y = -y };
    }
    var non_collinear = false;
    for (2..count) |index| {
        const cross = (original[1].x - original[0].x) * (original[index].y - original[0].y)
                    - (original[1].y - original[0].y) * (original[index].x - original[0].x);
        if (cross != 0) { non_collinear = true; break; }
    }
    if (!non_collinear) return -1;
    var ids: [MAX_POINTS]usize = undefined;
    var upper: [MAX_POINTS]usize = undefined;
    var lower: [MAX_POINTS]usize = undefined;
    var hull: [MAX_POINTS]usize = undefined;
    var left_index: usize = 0;
    var right_index: usize = 0;
    for (0..count) |index| {
        ids[index] = index;
        if (original[index].x < original[left_index].x) left_index = index;
        if (original[index].x > original[right_index].x) right_index = index;
    }
    var upper_count: usize = 0;
    var lower_count: usize = 0;
    connectUpper(upper_points[0..count], ids[0..count], left_index, right_index,
        upper[0..], &upper_count);
    connectUpper(lower_points[0..count], ids[0..count], left_index, right_index,
        lower[0..], &lower_count);
    var hull_count: usize = 0;
    for (lower[0..lower_count]) |id| appendUnique(hull[0..], &hull_count, id);
    var index = upper_count;
    while (index > 2) {
        index -= 1;
        appendUnique(hull[0..], &hull_count, upper[index - 1]);
    }
    const byte_count = 16 * hull_count;
    if (output == null or output_capacity < byte_count) return -2;
    for (0..hull_count) |i| {
        const point = original[hull[i]];
        storeI64Le(output, 16 * i, point.x);
        storeI64Le(output, 16 * i + 8, point.y);
    }
    return @intCast(byte_count);
}
