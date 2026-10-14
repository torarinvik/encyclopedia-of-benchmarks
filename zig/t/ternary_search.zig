/// Ternary search in an ascending sequence for the shared benchmark contract.
export fn ternary_search(values: [*]const i64, length: usize, target: i64) i64 {
    const slice = values[0..length];
    var low: usize = 0;
    var high = length;
    while (low < high) {
        const third = (high - low) / 3;
        const first = low + third;
        const second = high - third - 1;
        const first_value = slice[first];
        const second_value = slice[second];
        if (first_value == target) return @intCast(first);
        if (second_value == target) return @intCast(second);
        if (target < first_value) {
            high = first;
        } else if (target > second_value) {
            low = second + 1;
        } else {
            low = first + 1;
            high = second;
        }
    }
    return -1;
}
