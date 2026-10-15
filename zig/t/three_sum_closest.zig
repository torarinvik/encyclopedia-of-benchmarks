const MAX_ITEMS: usize = 512;
const INVALID_RESULT: i64 = -9_000_000_000_000_000_000;

fn heapSiftDown(values: [*]i64, root_value: usize, end: usize) void {
    var root = root_value;
    while (root < end / 2) {
        var child = root * 2 + 1;
        if (child + 1 < end and values[child] < values[child + 1]) child += 1;
        if (values[root] >= values[child]) break;
        const temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}

fn heapSort(values: [*]i64, length: usize) void {
    var start = length / 2;
    while (start > 0) {
        start -= 1;
        heapSiftDown(values, start, length);
    }
    var end = length;
    while (end > 1) {
        end -= 1;
        const temporary = values[0]; values[0] = values[end]; values[end] = temporary;
        heapSiftDown(values, 0, end);
    }
}

fn absoluteDifference(left: i64, right: i64) i64 {
    const difference = left - right;
    return if (difference < 0) -difference else difference;
}

export fn three_sum_closest(input: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_ITEMS + 2) return INVALID_RESULT;
    const target = input[0];
    const count_value = input[1];
    if (target < -2147483648 or target > 2147483647 or count_value < 3 or count_value > MAX_ITEMS) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return INVALID_RESULT;
    var values: [MAX_ITEMS]i64 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 2];
        if (value < -2147483648 or value > 2147483647) return INVALID_RESULT;
        values[index] = value;
    }
    heapSort(values[0..].ptr, count);
    var best = values[0] + values[1] + values[2];
    var best_difference = absoluteDifference(target, best);
    for (0..count - 2) |first| {
        var left = first + 1;
        var right = count - 1;
        while (left < right) {
            const sum = values[first] + values[left] + values[right];
            const difference = absoluteDifference(target, sum);
            if (difference < best_difference or (difference == best_difference and sum < best)) {
                best = sum;
                best_difference = difference;
            }
            if (sum < target) left += 1
            else if (sum > target) right -= 1
            else return sum;
        }
    }
    return best;
}
