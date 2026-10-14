/// Shell sort with a halving gap sequence for the shared contract.
export fn shell_sort(values: [*]i64, length: usize) void {
    var gap = length / 2;
    while (gap > 0) {
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
        gap /= 2;
    }
}
