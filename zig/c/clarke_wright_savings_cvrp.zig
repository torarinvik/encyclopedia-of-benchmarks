const Saving = struct {
    value: i64,
    i: usize,
    j: usize,
};

fn savingBefore(a: Saving, b: Saving) bool {
    if (a.value != b.value) return a.value > b.value;
    if (a.i != b.i) return a.i < b.i;
    return a.j < b.j;
}

fn reverseRoute(routes: *[49]usize, slot: usize, length: usize) void {
    var left: usize = 0;
    var right = length - 1;
    while (left < right) {
        const temporary = routes[slot * 7 + left];
        routes[slot * 7 + left] = routes[slot * 7 + right];
        routes[slot * 7 + right] = temporary;
        left += 1;
        right -= 1;
    }
}

fn compareRoutes(a: *const [49]usize, a_slot: usize, a_length: usize,
    b: *const [49]usize, b_slot: usize, b_length: usize) i32 {
    const shared = @min(a_length, b_length);
    for (0..shared) |index| {
        const av = a[a_slot * 7 + index];
        const bv = b[b_slot * 7 + index];
        if (av < bv) return -1;
        if (av > bv) return 1;
    }
    if (a_length < b_length) return -1;
    if (a_length > b_length) return 1;
    return 0;
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(bits >> shift);
    }
}

export fn clarke_wright_savings_cvrp(
    input_opt: ?[*]const i64,
    length: usize,
    output_opt: ?[*]u8,
    capacity: usize,
) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > 74) return -1;
    const n64 = input[0];
    const capacity64 = input[1];
    if (n64 < 0 or n64 > 7 or capacity64 < 1 or capacity64 > 100) return -1;
    const n: usize = @intCast(n64);
    const vehicle_capacity = capacity64;
    const width = n + 1;
    if (length != 2 + n + width * width) return -1;

    var demand: [8]i64 = @splat(0);
    for (1..n + 1) |customer| {
        const value = input[1 + customer];
        if (value < 1 or value > vehicle_capacity) return -1;
        demand[customer] = value;
    }
    var distance: [64]i64 = @splat(0);
    const offset = 2 + n;
    for (0..width) |i| {
        for (0..width) |j| {
            const value = input[offset + i * width + j];
            if (value < 0 or value > 1000 or (i == j and value != 0)) return -1;
            distance[i * 8 + j] = value;
        }
    }
    for (0..width) |i| {
        for (i + 1..width) |j| {
            if (distance[i * 8 + j] != distance[j * 8 + i]) return -1;
        }
    }

    var routes: [49]usize = @splat(0);
    var route_length: [7]usize = @splat(0);
    var load: [7]i64 = @splat(0);
    var active: [7]bool = @splat(false);
    for (0..n) |slot| {
        routes[slot * 7] = slot + 1;
        route_length[slot] = 1;
        load[slot] = demand[slot + 1];
        active[slot] = true;
    }

    var pairs: [21]Saving = @splat(.{ .value = 0, .i = 0, .j = 0 });
    var pair_count: usize = 0;
    for (1..n + 1) |i| {
        for (i + 1..n + 1) |j| {
            pairs[pair_count] = .{
                .value = distance[i] + distance[j] - distance[i * 8 + j],
                .i = i,
                .j = j,
            };
            pair_count += 1;
        }
    }
    for (0..pair_count) |i| {
        for (i + 1..pair_count) |j| {
            if (savingBefore(pairs[j], pairs[i])) {
                const temporary = pairs[i];
                pairs[i] = pairs[j];
                pairs[j] = temporary;
            }
        }
    }

    for (0..pair_count) |pair_index| {
        const pair = pairs[pair_index];
        if (pair.value <= 0) break;
        var route_i: usize = 7;
        var route_j: usize = 7;
        var position_i: usize = 0;
        var position_j: usize = 0;
        for (0..n) |slot| {
            if (!active[slot]) continue;
            for (0..route_length[slot]) |position| {
                const customer = routes[slot * 7 + position];
                if (customer == pair.i) {
                    route_i = slot;
                    position_i = position;
                }
                if (customer == pair.j) {
                    route_j = slot;
                    position_j = position;
                }
            }
        }
        if (route_i == route_j or route_i == 7 or route_j == 7) continue;
        if ((position_i != 0 and position_i + 1 != route_length[route_i]) or
            (position_j != 0 and position_j + 1 != route_length[route_j]) or
            load[route_i] + load[route_j] > vehicle_capacity) continue;
        if (position_i == 0) reverseRoute(&routes, route_i, route_length[route_i]);
        if (position_j + 1 == route_length[route_j]) reverseRoute(&routes, route_j, route_length[route_j]);

        const old_length = route_length[route_i];
        for (0..route_length[route_j]) |position| {
            routes[route_i * 7 + old_length + position] = routes[route_j * 7 + position];
        }
        route_length[route_i] += route_length[route_j];
        load[route_i] += load[route_j];
        active[route_j] = false;
        route_length[route_j] = 0;
        load[route_j] = 0;
    }

    var final_routes: [49]usize = @splat(0);
    var final_length: [7]usize = @splat(0);
    var route_count: usize = 0;
    for (0..n) |slot| {
        if (!active[slot]) continue;
        var reverse_first = false;
        for (0..route_length[slot]) |position| {
            const forward = routes[slot * 7 + position];
            const backward = routes[slot * 7 + route_length[slot] - 1 - position];
            if (forward != backward) {
                reverse_first = forward > backward;
                break;
            }
        }
        if (reverse_first) reverseRoute(&routes, slot, route_length[slot]);
        for (0..route_length[slot]) |position| {
            final_routes[route_count * 7 + position] = routes[slot * 7 + position];
        }
        final_length[route_count] = route_length[slot];
        route_count += 1;
    }
    for (0..route_count) |i| {
        for (i + 1..route_count) |j| {
            if (compareRoutes(&final_routes, i, final_length[i], &final_routes, j, final_length[j]) > 0) {
                for (0..7) |position| {
                    const temporary = final_routes[i * 7 + position];
                    final_routes[i * 7 + position] = final_routes[j * 7 + position];
                    final_routes[j * 7 + position] = temporary;
                }
                const temporary_length = final_length[i];
                final_length[i] = final_length[j];
                final_length[j] = temporary_length;
            }
        }
    }

    var words: [15]i64 = @splat(0);
    var word_count: usize = 0;
    words[word_count] = @intCast(route_count);
    word_count += 1;
    for (0..route_count) |route| {
        words[word_count] = @intCast(final_length[route]);
        word_count += 1;
        for (0..final_length[route]) |position| {
            words[word_count] = @intCast(final_routes[route * 7 + position]);
            word_count += 1;
        }
    }
    const bytes = word_count * 8;
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    for (0..word_count) |word| putI64(output, word * 8, words[word]);
    return @intCast(bytes);
}
