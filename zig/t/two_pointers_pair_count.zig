const MAX_VALUES: usize = 256;
const MAX_INPUT_LENGTH: usize = MAX_VALUES + 2;

fn siftDown(values: [*]i64, root_start: usize, end: usize) void {
    var root = root_start;
    while (root < end / 2) {
        var child = root * 2 + 1;
        if (child + 1 < end and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) break;
        const temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn heapSort(values: [*]i64, length: usize) void {
    var start = length / 2;
    while (start > 0) {
        start -= 1;
        siftDown(values, start, length);
    }
    var ending = length;
    while (ending > 1) {
        ending -= 1;
        const temporary = values[0];
        values[0] = values[ending];
        values[ending] = temporary;
        siftDown(values, 0, ending);
    }
}

export fn two_pointers_pair_count(input_pointer: ?[*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_pointer orelse return -1;
    const target = input[0];
    const count_value = input[1];
    if (count_value < 0 or count_value > 256 or
        length != 2 + @as(usize, @intCast(count_value)) or
        target < -2_000_000 or target > 2_000_000) return -1;

    const count: usize = @intCast(count_value);
    var values = [_]i64{0} ** MAX_VALUES;
    for (0..count) |index| {
        const value = input[2 + index];
        if (value < -1_000_000 or value > 1_000_000) return -1;
        values[index] = value;
    }
    heapSort(&values, count);
    if (count < 2) return 0;
    for (1..count) |index| {
        if (values[index - 1] == values[index]) return -1;
    }

    var left: usize = 0;
    var right = count - 1;
    var pairs: i64 = 0;
    while (left < right) {
        const sum = values[left] + values[right];
        if (sum < target) {
            left += 1;
        } else if (sum > target) {
            right -= 1;
        } else {
            pairs += 1;
            left += 1;
        }
    }
    return pairs;
}

