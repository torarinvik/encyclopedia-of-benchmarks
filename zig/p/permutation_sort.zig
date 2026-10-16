const MAX_LENGTH: usize = 8;
const INVALID_RESULT: i64 = -1;

fn is_sorted(values: []const i64) bool {
    for (1..values.len) |index| {
        if (values[index - 1] > values[index]) return false;
    }
    return true;
}

export fn permutation_sort(values: [*c]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > MAX_LENGTH) return INVALID_RESULT;

    var working: [MAX_LENGTH]i64 = undefined;
    var counters: [MAX_LENGTH]usize = @splat(0);
    for (0..length) |index| working[index] = values[index];

    var checked: i64 = 1;
    if (is_sorted(working[0..length])) return checked;

    var index: usize = 0;
    while (index < length) {
        if (counters[index] < index) {
            const swap_index: usize = if (index % 2 == 0) 0 else counters[index];
            const temporary = working[swap_index];
            working[swap_index] = working[index];
            working[index] = temporary;
            counters[index] += 1;
            checked += 1;
            if (is_sorted(working[0..length])) return checked;
            index = 0;
        } else {
            counters[index] = 0;
            index += 1;
        }
    }
    return INVALID_RESULT;
}
