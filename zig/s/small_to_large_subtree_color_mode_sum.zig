const MAX_N: usize = 64;
const CELLS: usize = MAX_N * MAX_N;

fn addColor(map: usize, color: usize, amount: i64, labels: *const [MAX_N]i64,
    frequencies: *[CELLS]i64, keys: *[CELLS]usize,
    lengths: *[MAX_N]usize, maximum: *[MAX_N]i64, modeSum: *[MAX_N]i64) void {
    const cell = map * MAX_N + color;
    const old = frequencies[cell];
    if (old == 0) {
        keys[map * MAX_N + lengths[map]] = color;
        lengths[map] += 1;
    }
    if (old > 0 and old == maximum[map]) modeSum[map] -= labels[color];
    const updated = old + amount;
    if (updated > maximum[map]) {
        maximum[map] = updated;
        modeSum[map] = labels[color];
    } else if (updated == maximum[map]) {
        modeSum[map] += labels[color];
    }
    frequencies[cell] = updated;
}

fn putWord(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn small_to_large_subtree_color_mode_sum(input: [*c]const i64,
    length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 129) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or length != 2 * @as(usize, @intCast(n_value))) return -1;
    const n: usize = @intCast(n_value);
    var parent: [MAX_N]usize = @splat(0);
    for (1..n) |vertex| {
        const p = packed[vertex];
        if (p < 0 or p >= @as(i64, @intCast(vertex))) return -1;
        parent[vertex] = @intCast(p);
    }
    var sorted: [MAX_N]i64 = @splat(0);
    for (0..n) |vertex| {
        const color = packed[n + vertex];
        if (color < -1000 or color > 1000) return -1;
        sorted[vertex] = color;
    }
    for (1..n) |i| {
        const value = sorted[i];
        var j = i;
        while (j > 0 and sorted[j - 1] > value) {
            sorted[j] = sorted[j - 1];
            j -= 1;
        }
        sorted[j] = value;
    }
    var labels: [MAX_N]i64 = @splat(0);
    var distinct: usize = 0;
    for (0..n) |i| {
        if (distinct == 0 or labels[distinct - 1] != sorted[i]) {
            labels[distinct] = sorted[i];
            distinct += 1;
        }
    }
    var colorIndex: [MAX_N]usize = @splat(0);
    for (0..n) |vertex| {
        var index: usize = 0;
        while (labels[index] != packed[n + vertex]) index += 1;
        colorIndex[vertex] = index;
    }
    if (output == null or capacity < 8 * n) return -2;

    var frequencies: [CELLS]i64 = @splat(0);
    var keys: [CELLS]usize = @splat(0);
    var mapLengths: [MAX_N]usize = @splat(0);
    var mapId: [MAX_N]usize = @splat(0);
    var maximum: [MAX_N]i64 = @splat(0);
    var modeSum: [MAX_N]i64 = @splat(0);
    var answers: [MAX_N]i64 = @splat(0);
    var cursor = n;
    while (cursor > 0) {
        cursor -= 1;
        const vertex = cursor;
        var largest = n;
        for (vertex + 1..n) |child| {
            if (parent[child] == vertex and
                (largest == n or mapLengths[mapId[child]] > mapLengths[mapId[largest]])) largest = child;
        }
        const map = if (largest == n) vertex else mapId[largest];
        for (vertex + 1..n) |child| {
            if (parent[child] != vertex or child == largest) continue;
            const small = mapId[child];
            for (0..mapLengths[small]) |i| {
                const color = keys[small * MAX_N + i];
                const amount = frequencies[small * MAX_N + color];
                addColor(map, color, amount, &labels, &frequencies, &keys,
                    &mapLengths, &maximum, &modeSum);
            }
        }
        addColor(map, colorIndex[vertex], 1, &labels, &frequencies, &keys,
            &mapLengths, &maximum, &modeSum);
        mapId[vertex] = map;
        answers[vertex] = modeSum[map];
    }
    for (0..n) |vertex| putWord(output, vertex * 8, answers[vertex]);
    return @intCast(8 * n);
}
