/// One-based quickselect using the pinned last-element partition.
const MAX_LENGTH: usize = 256;
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

fn partitionValues(values: *[MAX_LENGTH]i32, low_value: usize, high_value: usize) usize {
    const pivot = high_value;
    var i = low_value;
    var j = high_value - 1;
    while (true) {
        while (values[i] < values[pivot]) i += 1;
        while (j > 0 and values[j] > values[pivot]) j -= 1;
        if (j == 0 or i >= j) break;
        if (values[i] == values[j]) {
            i += 1;
            j -= 1;
        } else {
            const temporary = values[i];
            values[i] = values[j];
            values[j] = temporary;
        }
    }
    const temporary = values[i];
    values[i] = values[pivot];
    values[pivot] = temporary;
    return i;
}

export fn kth_smallest(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_LENGTH + 2) return INVALID_RESULT;
    const n_value = input[0];
    const k_value = input[1];
    if (n_value < 1 or n_value > MAX_LENGTH or k_value < 1 or k_value > n_value or
        length != @as(usize, @intCast(n_value)) + 2) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    var values: [MAX_LENGTH]i32 = undefined;
    for (0..n) |index| {
        const value = input[index + 2];
        if (value < -2147483648 or value > 2147483647) return INVALID_RESULT;
        values[index] = @intCast(value);
    }

    var low: usize = 0;
    var high = n - 1;
    var k: usize = @intCast(k_value);
    while (low < high) {
        const pivot = partitionValues(&values, low, high);
        const pivot_rank = pivot - low + 1;
        if (k == pivot_rank) return values[pivot];
        if (k < pivot_rank) {
            high = pivot - 1;
        } else {
            low = pivot + 1;
            k -= pivot_rank;
        }
    }
    return values[low];
}
