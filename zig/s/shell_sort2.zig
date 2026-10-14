/// Shell sort using the Ciura gap sequence.
const CIURA_GAPS = [_]usize{ 701, 301, 132, 57, 23, 10, 4, 1 };

export fn shell_sort2(values: [*]i64, length: usize) void {
    for (CIURA_GAPS) |gap| {
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
