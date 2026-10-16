const MAX_VERTICES: usize = 8;
const MAX_EDGES: i64 = 56;
const INF: i64 = 2305843009213693951;

fn putI64Le(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn graph_peripherality(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const n_value = input[0];
    const edge_value = input[1];
    if (n_value < 1 or n_value > 8 or edge_value < 0 or edge_value > MAX_EDGES or
        edge_value > n_value * (n_value - 1) or length != 2 + 3 * @as(usize, @intCast(edge_value))) return -1;
    const n: usize = @intCast(n_value);
    const edge_count: usize = @intCast(edge_value);
    var distance: [64]i64 = @splat(INF);
    for (0..n) |i| distance[i * MAX_VERTICES + i] = 0;
    for (0..edge_count) |edge| {
        const source_value = input[2 + 3 * edge];
        const destination_value = input[3 + 3 * edge];
        const weight = input[4 + 3 * edge];
        if (source_value < 0 or source_value >= n_value or destination_value < 0 or destination_value >= n_value or
            source_value == destination_value or weight < 1 or weight > 1_000_000) return -1;
        const source: usize = @intCast(source_value);
        const destination: usize = @intCast(destination_value);
        const cell = source * MAX_VERTICES + destination;
        if (distance[cell] != INF) return -1;
        distance[cell] = weight;
    }
    for (0..n) |middle| {
        for (0..n) |source| {
            const first = distance[source * MAX_VERTICES + middle];
            if (first == INF) continue;
            for (0..n) |destination| {
                const second = distance[middle * MAX_VERTICES + destination];
                const cell = source * MAX_VERTICES + destination;
                if (second != INF and first + second < distance[cell]) distance[cell] = first + second;
            }
        }
    }

    if (n > 1) {
        for (0..n) |source| {
            for (0..n) |destination| {
                if (source != destination and distance[source * MAX_VERTICES + destination] == INF) return -1;
            }
        }
    }

    var peripheral: i64 = -1;
    var far: i64 = -1;
    var peripheral_infinite = false;
    var far_infinite = false;
    var any_reachable = false;
    var best_eccentricity: i64 = -1;
    var best_farness: i64 = -1;
    if (n == 1) {
        peripheral = 0;
        far = 0;
        best_eccentricity = 0;
        best_farness = 0;
    } else {
        for (0..n) |source| {
            var found = false;
            var eccentricity: i64 = 0;
            var farness: i64 = 0;
            for (0..n) |destination| {
                const value = distance[source * MAX_VERTICES + destination];
                if (destination == source or value == INF or value == 0) continue;
                found = true;
                if (value > eccentricity) eccentricity = value;
                farness += value;
            }
            if (found) any_reachable = true;
            const infinite = !found;
            if (peripheral < 0 or (infinite and !peripheral_infinite) or
                (infinite == peripheral_infinite and (infinite or eccentricity > best_eccentricity or
                 (eccentricity == best_eccentricity and @as(i64, @intCast(source)) < peripheral)))) {
                peripheral = @intCast(source);
                peripheral_infinite = infinite;
                best_eccentricity = eccentricity;
            }
            if (far < 0 or (infinite and !far_infinite) or
                (infinite == far_infinite and (infinite or farness > best_farness or
                 (farness == best_farness and @as(i64, @intCast(source)) < far)))) {
                far = @intCast(source);
                far_infinite = infinite;
                best_farness = farness;
            }
        }
        if (!any_reachable) {
            peripheral = -1; far = -1; best_eccentricity = -1; best_farness = -1;
        } else {
            if (peripheral_infinite) best_eccentricity = -1;
            if (far_infinite) best_farness = -1;
        }
    }
    if (output == null or capacity < 32) return -2;
    putI64Le(output, 0, peripheral);
    putI64Le(output, 1, best_eccentricity);
    putI64Le(output, 2, far);
    putI64Le(output, 3, best_farness);
    return 32;
}
