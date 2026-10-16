const MAX_VALUES: usize = 25;
const MAX_INPUT_LENGTH: usize = 28;

fn insertionSort(values: []i64) void {
    for (1..values.len) |index| {
        const value = values[index];
        var position = index;
        while (position > 0 and values[position - 1] > value) {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
}

fn selectKth(values: []i64, rank: usize) i64 {
    var medians: [5]i64 = undefined;
    var median_count: usize = 0;
    var start: usize = 0;
    while (start < values.len) : (start += 5) {
        const end = @min(start + 5, values.len);
        insertionSort(values[start..end]);
        medians[median_count] = values[(start + end) / 2];
        median_count += 1;
    }
    insertionSort(medians[0..median_count]);
    const pivot = medians[(median_count - 1) / 2];

    var lower: [MAX_VALUES]i64 = undefined;
    var higher: [MAX_VALUES]i64 = undefined;
    var lower_count: usize = 0;
    var higher_count: usize = 0;
    for (values) |value| {
        if (value < pivot) {
            lower[lower_count] = value;
            lower_count += 1;
        } else if (value > pivot) {
            higher[higher_count] = value;
            higher_count += 1;
        }
    }
    if (rank < lower_count) return selectKth(lower[0..lower_count], rank);
    if (rank > lower_count) return selectKth(higher[0..higher_count], rank - lower_count - 1);
    return pivot;
}

export fn median_search(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const count_value = input[0];
    const rank_value = input[1];
    if (count_value < 1 or count_value > 25 or rank_value < 0 or rank_value >= count_value) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;

    var values: [MAX_VALUES]i64 = undefined;
    for (0..count) |index| {
        const value = input[index + 2];
        if (value < 0 or value > 2_147_483_647) return -1;
        for (0..index) |previous| {
            if (values[previous] == value) return -1;
        }
        values[index] = value;
    }
    return selectKth(values[0..count], @intCast(rank_value));
}
