/// Deterministic bogo sort for the shared, bounded portable workload.
export fn bogo_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    var state: u64 = 2_654_435_769;
    while (true) {
        var sorted = true;
        for (1..length) |check_index| {
            if (values[check_index - 1] > values[check_index]) {
                sorted = false;
                break;
            }
        }
        if (sorted) return;
        var index = length;
        while (index > 1) {
            index -= 1;
            state = (state * 1_664_525 + 1_013_904_223) % 4_294_967_296;
            const other: usize = @intCast((state / 65_536) % @as(u64, @intCast(index + 1)));
            const temporary = values[index];
            values[index] = values[other];
            values[other] = temporary;
        }
    }
}
