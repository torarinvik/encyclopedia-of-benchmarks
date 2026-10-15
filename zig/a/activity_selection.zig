/// Count a maximum set of non-overlapping half-open activities.
export fn activity_selection(input: [*]const i64, length: usize) i64 {
    if (length == 0) return -1;
    if (input[0] < 0 or input[0] > 64) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + 2 * count) return -1;
    if (count == 0) return 0;
    var starts: [64]i64 = @splat(0);
    var finishes: [64]i64 = @splat(0);
    for (0..count) |index| {
        starts[index] = input[1 + 2 * index];
        finishes[index] = input[2 + 2 * index];
        if (starts[index] > finishes[index]) return -1;
    }
    for (1..count) |index| {
        const start = starts[index];
        const finish = finishes[index];
        var position = index;
        while (position > 0 and (finishes[position - 1] > finish or
            (finishes[position - 1] == finish and starts[position - 1] > start))) {
            starts[position] = starts[position - 1];
            finishes[position] = finishes[position - 1];
            position -= 1;
        }
        starts[position] = start;
        finishes[position] = finish;
    }
    var selected: i64 = 1;
    var last_finish = finishes[0];
    for (1..count) |index| {
        if (starts[index] >= last_finish) {
            selected += 1;
            last_finish = finishes[index];
        }
    }
    return selected;
}
