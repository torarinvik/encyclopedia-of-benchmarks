const MAX_VALUES = 1024;

fn mergeRange(values: [*]i64, scratch: [*]i64, low: usize, high: usize) void {
    if (high - low <= 1) return;
    const middle = low + (high - low) / 2;
    mergeRange(values, scratch, low, middle);
    mergeRange(values, scratch, middle, high);
    var left = low;
    var right = middle;
    var output = low;
    while (left < middle and right < high) {
        if (values[left] <= values[right]) {
            scratch[output] = values[left];
            left += 1;
        } else {
            scratch[output] = values[right];
            right += 1;
        }
        output += 1;
    }
    while (left < middle) : (left += 1) { scratch[output] = values[left]; output += 1; }
    while (right < high) : (right += 1) { scratch[output] = values[right]; output += 1; }
    for (low..high) |index| values[index] = scratch[index];
}

export fn merge_sorter(values: [*]i64, length: usize) void {
    if (length > MAX_VALUES) return;
    var scratch: [MAX_VALUES]i64 = undefined;
    mergeRange(values, scratch[0..].ptr, 0, length);
}
