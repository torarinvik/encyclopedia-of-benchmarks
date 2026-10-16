/// Shell sort using the pinned Python 1.3 gap shrink factor.
export fn shrink_shell_sort(values: [*]i64, length: usize) void {
    var gap = length;
    while (gap > 1) {
        gap = @intFromFloat(@as(f64, @floatFromInt(gap)) / 1.3);
        var index = gap;
        while (index < length) : (index += 1) {
            const key = values[index];
            var position = index;
            while (position >= gap and values[position - gap] > key) {
                values[position] = values[position - gap];
                position -= gap;
            }
            values[position] = key;
        }
    }
}
