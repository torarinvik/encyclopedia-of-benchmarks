/// Return unique sorted zero-sum triplets using sort-and-two-pointers.
const MAX_ITEMS: usize = 257;
const BYTES_PER_TRIPLET: usize = 12;

fn siftDown(values: [*]i64, root_value: usize, end: usize) void {
    var root = root_value;
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

fn storeI32Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| {
        output[offset + byte] = @truncate(bits >> @as(u5, @intCast(byte * 8)));
    }
}

fn enumerateTriplets(values: [*]const i64, length: usize,
                     output: [*]u8, write_output: bool) usize {
    var result_count: usize = 0;
    for (0..length -| 2) |first| {
        if (first > 0 and values[first] == values[first - 1]) continue;
        var left = first + 1;
        var right = length - 1;
        while (left < right) {
            const sum = values[first] + values[left] + values[right];
            if (sum < 0) {
                left += 1;
            } else if (sum > 0) {
                right -= 1;
            } else {
                if (write_output) {
                    const offset = result_count * BYTES_PER_TRIPLET;
                    storeI32Le(output, offset, values[first]);
                    storeI32Le(output, offset + 4, values[left]);
                    storeI32Le(output, offset + 8, values[right]);
                }
                result_count += 1;
                left += 1;
                right -= 1;
                while (left < right and values[left] == values[left - 1]) left += 1;
                while (left < right and values[right] == values[right + 1]) right -= 1;
            }
        }
    }
    return result_count;
}

export fn three_sum(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_ITEMS) return -1;
    var values: [MAX_ITEMS]i64 = @splat(0);
    for (0..length) |index| {
        const value = input[index];
        if (value < -100000 or value > 100000) return -1;
        values[index] = value;
    }
    heapSort(&values, length);

    const maximum_bytes: usize = if (length < 2) 0 else
        length * (length - 1) / 2 * BYTES_PER_TRIPLET;
    if (output_capacity < maximum_bytes) {
        const needed = enumerateTriplets(&values, length, output, false) * BYTES_PER_TRIPLET;
        if (output_capacity < needed) return -2;
    }
    return @intCast(enumerateTriplets(&values, length, output, true));
}
