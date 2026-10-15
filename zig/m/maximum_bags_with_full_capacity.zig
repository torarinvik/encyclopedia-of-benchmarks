fn siftDown(values: []i64, root_start: usize, finish: usize) void {
    var root = root_start;
    while (root < finish / 2) {
        var child = root * 2 + 1;
        if (child + 1 < finish and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) break;
        const temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

export fn maximum_bags_with_full_capacity(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 16384) return -1;
    var remaining = input[0];
    if (remaining < 0 or remaining > 1000000000) return -1;
    if (input[1] < 0 or input[1] > 8191) return -1;
    const count: usize = @intCast(input[1]);
    if (length != 2 + 2 * count) return -1;
    var deficits: [8191]i64 = undefined;
    for (0..count) |index| {
        const capacity = input[2 + index];
        const rocks = input[2 + count + index];
        if (capacity < 1 or capacity > 100000 or rocks < 0 or rocks > capacity) return -1;
        deficits[index] = capacity - rocks;
    }
    for (0..(count / 2)) |offset| {
        siftDown(deficits[0..], count / 2 - 1 - offset, count);
    }
    var finish = count;
    while (finish > 1) {
        finish -= 1;
        const temporary = deficits[0];
        deficits[0] = deficits[finish];
        deficits[finish] = temporary;
        siftDown(deficits[0..], 0, finish);
    }
    var full_bags: i64 = 0;
    for (0..count) |index| {
        if (deficits[index] > remaining) break;
        remaining -= deficits[index];
        full_bags += 1;
    }
    return full_bags;
}
