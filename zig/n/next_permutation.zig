/// Replace a permutation by its lexicographic successor, wrapping to minimum.
const MAX_LENGTH: usize = 128;

fn reverse(values: *[MAX_LENGTH]i32, left: usize, right: usize) void {
    var low = left;
    var high = right;
    while (low < high) {
        const temporary = values[low];
        values[low] = values[high];
        values[high] = temporary;
        low += 1;
        high -= 1;
    }
}

fn storeI32Le(output: [*]u8, position: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[position + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
}

export fn next_permutation(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_LENGTH + 1) return -1;
    const n_value = input[0];
    if (n_value < 0 or n_value > MAX_LENGTH or length != @as(usize, @intCast(n_value)) + 1) return -1;
    const n: usize = @intCast(n_value);
    var values: [MAX_LENGTH]i32 = undefined;
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[i] = @intCast(value);
    }
    const required = n * 4;
    if (output_capacity < required) return -2;
    var pivot = n;
    var index = n;
    while (index > 1) {
        index -= 1;
        if (values[index - 1] < values[index]) { pivot = index - 1; break; }
    }
    if (pivot == n) {
        if (n > 1) reverse(&values, 0, n - 1);
    } else {
        var successor = n - 1;
        while (values[successor] <= values[pivot]) successor -= 1;
        const temporary = values[pivot];
        values[pivot] = values[successor];
        values[successor] = temporary;
        if (pivot + 1 < n) reverse(&values, pivot + 1, n - 1);
    }
    for (0..n) |i| storeI32Le(output, i * 4, values[i]);
    return @intCast(n);
}
