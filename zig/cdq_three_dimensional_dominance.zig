const MAX_N: usize = 64;
const MAX_PARSEABLE_LENGTH: usize = 194;

const Point = struct {
    x: i64,
    y: i64,
    z: i64,
    multiplicity: i64,
    z_rank: usize,
    original_index: usize,
};

const Workspace = struct {
    points: [MAX_N]Point,
    original_group: [MAX_N]usize,
    dominated: [MAX_N]i64,
    bit: [MAX_N + 1]i64,
    source_order: [MAX_N]usize,
    target_order: [MAX_N]usize,
    z_values: [MAX_N]i64,
};

fn pointLess(a: Point, b: Point) bool {
    if (a.x != b.x) return a.x < b.x;
    if (a.y != b.y) return a.y < b.y;
    return a.z < b.z;
}

fn sameCoordinates(a: Point, b: Point) bool {
    return a.x == b.x and a.y == b.y and a.z == b.z;
}

fn bitAdd(work: *Workspace, start: usize, delta: i64, limit: usize) void {
    var index = start;
    while (index <= limit) {
        work.bit[index] += delta;
        index += index & (~index +% 1);
    }
}

fn bitSum(work: *const Workspace, start: usize) i64 {
    var index = start;
    var total: i64 = 0;
    while (index > 0) {
        total += work.bit[index];
        index -= index & (~index +% 1);
    }
    return total;
}

fn cdq(work: *Workspace, left: usize, right: usize, group_count: usize) void {
    if (left >= right) return;
    const middle = left + (right - left) / 2;
    cdq(work, left, middle, group_count);
    cdq(work, middle + 1, right, group_count);

    var source_cursor = left;
    for (middle + 1..right + 1) |target_position| {
        const target = work.source_order[target_position];
        while (source_cursor <= middle) {
            const source = work.source_order[source_cursor];
            if (work.points[source].y > work.points[target].y) break;
            bitAdd(work, work.points[source].z_rank, work.points[source].multiplicity, group_count);
            source_cursor += 1;
        }
        work.dominated[target] += bitSum(work, work.points[target].z_rank);
    }
    for (left..source_cursor) |i| {
        const source = work.source_order[i];
        bitAdd(work, work.points[source].z_rank, -work.points[source].multiplicity, group_count);
    }

    var left_cursor = left;
    var right_cursor = middle + 1;
    var destination = left;
    while (left_cursor <= middle and right_cursor <= right) {
        const left_point = work.source_order[left_cursor];
        const right_point = work.source_order[right_cursor];
        if (work.points[left_point].y <= work.points[right_point].y) {
            work.target_order[destination] = left_point;
            left_cursor += 1;
        } else {
            work.target_order[destination] = right_point;
            right_cursor += 1;
        }
        destination += 1;
    }
    while (left_cursor <= middle) {
        work.target_order[destination] = work.source_order[left_cursor];
        left_cursor += 1;
        destination += 1;
    }
    while (right_cursor <= right) {
        work.target_order[destination] = work.source_order[right_cursor];
        right_cursor += 1;
        destination += 1;
    }
    for (left..right + 1) |i| work.source_order[i] = work.target_order[i];
}

export fn cdq_three_dimensional_dominance(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 1 or input[0] > @as(i64, MAX_N)) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 3 * n) return -1;

    var work = Workspace{
        .points = [_]Point{.{ .x = 0, .y = 0, .z = 0, .multiplicity = 0, .z_rank = 0, .original_index = 0 }} ** MAX_N,
        .original_group = [_]usize{0} ** MAX_N,
        .dominated = [_]i64{0} ** MAX_N,
        .bit = [_]i64{0} ** (MAX_N + 1),
        .source_order = [_]usize{0} ** MAX_N,
        .target_order = [_]usize{0} ** MAX_N,
        .z_values = [_]i64{0} ** MAX_N,
    };
    for (0..n) |i| {
        const x = input[1 + 3 * i];
        const y = input[2 + 3 * i];
        const z = input[3 + 3 * i];
        if (x < -1000 or x > 1000 or y < -1000 or y > 1000 or z < -1000 or z > 1000) return -1;
        work.points[i] = .{ .x = x, .y = y, .z = z, .multiplicity = 1, .z_rank = 0, .original_index = i };
    }
    for (1..n) |i| {
        const value = work.points[i];
        var j = i;
        while (j > 0 and pointLess(value, work.points[j - 1])) {
            work.points[j] = work.points[j - 1];
            j -= 1;
        }
        work.points[j] = value;
    }

    var group_count: usize = 0;
    for (0..n) |i| {
        const point = work.points[i];
        if (group_count > 0 and sameCoordinates(point, work.points[group_count - 1])) {
            work.points[group_count - 1].multiplicity += 1;
            work.original_group[point.original_index] = group_count - 1;
        } else {
            work.points[group_count] = point;
            work.points[group_count].multiplicity = 1;
            work.original_group[point.original_index] = group_count;
            group_count += 1;
        }
    }

    for (0..group_count) |i| work.z_values[i] = work.points[i].z;
    for (1..group_count) |i| {
        const value = work.z_values[i];
        var j = i;
        while (j > 0 and value < work.z_values[j - 1]) {
            work.z_values[j] = work.z_values[j - 1];
            j -= 1;
        }
        work.z_values[j] = value;
    }
    var z_count: usize = 0;
    for (0..group_count) |i| {
        const value = work.z_values[i];
        if (z_count == 0 or value != work.z_values[z_count - 1]) {
            work.z_values[z_count] = value;
            z_count += 1;
        }
    }
    for (0..group_count) |i| {
        var low: usize = 0;
        var high = z_count;
        while (low < high) {
            const middle = low + (high - low) / 2;
            if (work.z_values[middle] < work.points[i].z) low = middle + 1 else high = middle;
        }
        work.points[i].z_rank = low + 1;
        work.source_order[i] = i;
    }

    if (group_count > 1) cdq(&work, 0, group_count - 1, z_count);
    var result: i64 = 0;
    for (0..n) |i| {
        const group = work.original_group[i];
        const count = work.dominated[group] + work.points[group].multiplicity - 1;
        result += @as(i64, @intCast(i + 1)) * count;
    }
    return result;
}
