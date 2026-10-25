const max_cities: usize = 7;
const conquer_threshold: usize = 3;
const scale: f64 = 1000.0;

fn cityDistance(x: *const [7]i64, y: *const [7]i64, a: usize, b: usize) f64 {
    const dx = @as(f64, @floatFromInt(x[a] - x[b]));
    const dy = @as(f64, @floatFromInt(y[a] - y[b]));
    return @sqrt(dx * dx + dy * dy);
}

fn subtreeSize(node: usize, count: usize) usize {
    if (node >= count) return 0;
    return 1 + subtreeSize(2 * node + 1, count) + subtreeSize(2 * node + 2, count);
}

fn collectPostorder(node: usize, count: usize, order: *[7]usize, length: *usize) void {
    if (node >= count) return;
    collectPostorder(2 * node + 1, count, order, length);
    collectPostorder(2 * node + 2, count, order, length);
    order[length.*] = node;
    length.* += 1;
}

fn reverseCycle(start: usize, size: usize, next: *[7]usize, prev: *[7]usize) void {
    var current = start;
    var i: usize = 0;
    while (i < size) : (i += 1) {
        const old_next = next[current];
        const old_prev = prev[current];
        next[current] = old_prev;
        prev[current] = old_next;
        current = old_next;
    }
}

fn conquer(order: *const [7]usize, count: usize, x: *const [7]i64, y: *const [7]i64,
            next: *[7]usize, prev: *[7]usize) usize {
    const cycle = order[0];
    next[cycle] = cycle;
    prev[cycle] = cycle;
    var index: usize = 1;
    while (index < count) : (index += 1) {
        const point = order[index];
        var min = cycle;
        var mindist = cityDistance(x, y, point, cycle);
        var tmp = next[cycle];
        while (tmp != cycle) : (tmp = next[tmp]) {
            const test = cityDistance(x, y, tmp, point);
            if (test < mindist) { mindist = test; min = tmp; }
        }
        const next_city = next[min];
        const prev_city = prev[min];
        const min_to_next = cityDistance(x, y, min, next_city);
        const min_to_prev = cityDistance(x, y, min, prev_city);
        const point_to_next = cityDistance(x, y, point, next_city);
        const point_to_prev = cityDistance(x, y, point, prev_city);
        if (point_to_prev - min_to_prev < point_to_next - min_to_next) {
            next[prev_city] = point; prev[point] = prev_city;
            next[point] = min; prev[min] = point;
        } else {
            prev[next_city] = point; next[point] = next_city;
            next[min] = point; prev[point] = min;
        }
    }
    return cycle;
}

fn mergeCycles(a: usize, b: usize, point: usize, size_a: usize, size_b: usize,
               x: *const [7]i64, y: *const [7]i64, next: *[7]usize, prev: *[7]usize) usize {
    var min = a;
    var mindist = cityDistance(x, y, point, a);
    var tmp = next[a];
    while (tmp != a) : (tmp = next[tmp]) {
        const test = cityDistance(x, y, point, tmp);
        if (test < mindist) { mindist = test; min = tmp; }
    }
    var next_city = next[min];
    var prev_city = prev[min];
    var min_to_next = cityDistance(x, y, min, next_city);
    var min_to_prev = cityDistance(x, y, min, prev_city);
    var point_to_next = cityDistance(x, y, point, next_city);
    var point_to_prev = cityDistance(x, y, point, prev_city);
    var n1: usize = 0; var p1: usize = 0;
    var tton1: f64 = 0.0; var ttop1: f64 = 0.0;
    if (point_to_prev - min_to_prev) < (point_to_next - min_to_next) {
        p1 = prev_city; n1 = min; tton1 = mindist; ttop1 = point_to_prev;
    } else {
        p1 = min; n1 = next_city; ttop1 = mindist; tton1 = point_to_next;
    }

    min = b;
    mindist = cityDistance(x, y, point, b);
    tmp = next[b];
    while (tmp != b) : (tmp = next[tmp]) {
        const test = cityDistance(x, y, point, tmp);
        if (test < mindist) { mindist = test; min = tmp; }
    }
    next_city = next[min]; prev_city = prev[min];
    min_to_next = cityDistance(x, y, min, next_city);
    min_to_prev = cityDistance(x, y, min, prev_city);
    point_to_next = cityDistance(x, y, point, next_city);
    point_to_prev = cityDistance(x, y, point, prev_city);
    var n2: usize = 0; var p2: usize = 0;
    var tton2: f64 = 0.0; var ttop2: f64 = 0.0;
    if (point_to_prev - min_to_prev) < (point_to_next - min_to_next) {
        p2 = prev_city; n2 = min; tton2 = mindist; ttop2 = point_to_prev;
    } else {
        p2 = min; n2 = next_city; ttop2 = mindist; tton2 = point_to_next;
    }

    const n1_to_n2 = cityDistance(x, y, n1, n2);
    const n1_to_p2 = cityDistance(x, y, n1, p2);
    const p1_to_n2 = cityDistance(x, y, p1, n2);
    const p1_to_p2 = cityDistance(x, y, p1, p2);
    var best = ttop1 + ttop2 + n1_to_n2;
    var choice: usize = 1;
    var test = ttop1 + tton2 + n1_to_p2;
    if (test < best) { choice = 2; best = test; }
    test = tton1 + ttop2 + p1_to_n2;
    if (test < best) { choice = 3; best = test; }
    test = tton1 + tton2 + p1_to_p2;
    if (test < best) choice = 4;

    if (choice == 1) {
        reverseCycle(n2, size_b, next, prev);
        next[p1] = point; prev[point] = p1; next[point] = p2; prev[p2] = point;
        next[n2] = n1; prev[n1] = n2;
    } else if (choice == 2) {
        next[p1] = point; prev[point] = p1; next[point] = n2; prev[n2] = point;
        next[p2] = n1; prev[n1] = p2;
    } else if (choice == 3) {
        next[p2] = point; prev[point] = p2; next[point] = n1; prev[n1] = point;
        next[p1] = n2; prev[n2] = p1;
    } else {
        reverseCycle(n1, size_a, next, prev);
        next[n1] = point; prev[point] = n1; next[point] = n2; prev[n2] = point;
        next[p2] = p1; prev[p1] = p2;
    }
    return point;
}

fn solveSubtree(node: usize, count: usize, x: *const [7]i64, y: *const [7]i64,
                next: *[7]usize, prev: *[7]usize) usize {
    const size = subtreeSize(node, count);
    if (size <= conquer_threshold) {
        var order: [7]usize = .{0} ** 7;
        var order_count: usize = 0;
        collectPostorder(node, count, &order, &order_count);
        return conquer(&order, order_count, x, y, next, prev);
    }
    const left = 2 * node + 1;
    const right = 2 * node + 2;
    const left_cycle = solveSubtree(left, count, x, y, next, prev);
    const right_cycle = solveSubtree(right, count, x, y, next, prev);
    return mergeCycles(left_cycle, right_cycle, node, subtreeSize(left, count), subtreeSize(right, count), x, y, next, prev);
}

pub export fn olden_tsp(input: [*c]const i64, length: usize) i64 {
    if (input == null or (length != 7 and length != 15)) return -1;
    const count_value = input[0];
    if (count_value != 3 and count_value != 7) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 2 * count) return -1;
    var x: [7]i64 = .{0} ** 7;
    var y: [7]i64 = .{0} ** 7;
    var next: [7]usize = .{0} ** 7;
    var prev: [7]usize = .{0} ** 7;
    var city: usize = 0;
    while (city < count) : (city += 1) {
        x[city] = input[1 + 2 * city];
        y[city] = input[2 + 2 * city];
        if (x[city] < -8 or x[city] > 8 or y[city] < -8 or y[city] > 8) return -1;
    }
    _ = solveSubtree(0, count, &x, &y, &next, &prev);
    var tour_length: f64 = 0.0;
    city = 0;
    var edge: usize = 0;
    while (edge < count) : (edge += 1) {
        const following = next[city];
        tour_length += cityDistance(&x, &y, city, following);
        city = following;
    }
    return @intFromFloat(@floor(tour_length * scale + 0.5));
}
