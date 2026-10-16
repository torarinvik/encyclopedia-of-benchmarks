fn valueAt(values: [10]i64, indices: [10]i64, position: usize) i64 {
    return values[@intCast(indices[position])];
}

fn nextPermutation(indices: *[10]i64, length: usize) bool {
    var pivot: isize = @as(isize, @intCast(length)) - 2;
    while (pivot >= 0 and indices[@intCast(pivot)] >= indices[@intCast(pivot + 1)]) : (pivot -= 1) {}
    if (pivot < 0) return false;
    var successor = length - 1;
    while (indices[successor] <= indices[@intCast(pivot)]) : (successor -= 1) {}
    const temp = indices[@intCast(pivot)];
    indices[@intCast(pivot)] = indices[successor];
    indices[successor] = temp;
    var left: usize = @intCast(pivot + 1);
    var right = length - 1;
    while (left < right) {
        const value = indices[left]; indices[left] = indices[right]; indices[right] = value;
        left += 1;
        right -= 1;
    }
    return true;
}

export fn problem68(gon_side: i64) i64 {
    if (gon_side < 3 or gon_side > 5) return -1;
    const n: usize = @intCast(gon_side);
    const length = 2 * n;
    var values = [_]i64{0} ** 10;
    var cursor: usize = 0;
    var value: i64 = @intCast(n + 1);
    while (value >= 1) : (value -= 1) { values[cursor] = value; cursor += 1; }
    value = @intCast(n + 2);
    while (value <= @as(i64, @intCast(2 * n))) : (value += 1) { values[cursor] = value; cursor += 1; }
    var indices = [_]i64{0} ** 10;
    for (0..length) |index| indices[index] = @intCast(index);
    while (true) {
        const total = valueAt(values, indices, 0) + valueAt(values, indices, 1) + valueAt(values, indices, 2);
        var magic = true;
        var minimum_outer = valueAt(values, indices, 0);
        for (1..n) |line| {
            const outer = if (line == n - 1) 2 * n - 1 else 2 * line + 1;
            const inner_left = 2 * line;
            const inner_right = if (line == n - 1) 1 else 2 * line + 2;
            if (valueAt(values, indices, outer) + valueAt(values, indices, inner_left) + valueAt(values, indices, inner_right) != total) magic = false;
            minimum_outer = @min(minimum_outer, valueAt(values, indices, outer));
        }
        if (magic and valueAt(values, indices, 0) == minimum_outer) {
            var result: i64 = 0;
            for (0..n) |line| {
                const outer = if (line == 0) 0 else if (line == n - 1) 2 * n - 1 else 2 * line + 1;
                const inner_left = if (line == 0) 1 else 2 * line;
                const inner_right = if (line == n - 1) 1 else if (line == 0) 2 else 2 * line + 2;
                const triple = [_]i64{ valueAt(values, indices, outer), valueAt(values, indices, inner_left), valueAt(values, indices, inner_right) };
                for (triple) |number| {
                    result = result * (if (number >= 10) 100 else 10) + number;
                }
            }
            return result;
        }
        if (!nextPermutation(&indices, length)) break;
    }
    return -1;
}
