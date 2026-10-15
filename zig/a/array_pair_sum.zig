const MAX_LENGTH: usize = 4096;

fn siftDown(values: *[MAX_LENGTH]i64, root_value: usize, count: usize) void {
    var root = root_value;
    while (root * 2 + 1 < count) {
        var child = root * 2 + 1;
        if (child + 1 < count and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) return;
        const temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

/// Sort signed 32-bit values and sum the first of every adjacent pair.
export fn array_pair_sum(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or length % 2 != 0 or (length != 0 and input == null)) return -1;
    var values: [MAX_LENGTH]i64 = @splat(0);
    for (0..length) |index| {
        const value = input[index];
        if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
        values[index] = value;
    }
    var start = length / 2;
    while (start > 0) {
        start -= 1;
        siftDown(&values, start, length);
    }
    var ending = length;
    while (ending > 1) {
        ending -= 1;
        const temporary = values[0];
        values[0] = values[ending];
        values[ending] = temporary;
        siftDown(&values, 0, ending);
    }
    var total: i64 = 0;
    var index: usize = 0;
    while (index < length) : (index += 2) total += values[index];
    return total;
}
