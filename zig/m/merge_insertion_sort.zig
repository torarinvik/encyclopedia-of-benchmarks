const MAX_VALUES = 256;
const MAX_PAIRS = MAX_VALUES / 2;

fn sortPairs(low: [*]i64, high: [*]i64, scratch_low: [*]i64, scratch_high: [*]i64, count: usize) void {
    var width: usize = 1;
    while (width < count) : (width *= 2) {
        var start: usize = 0;
        while (start < count) : (start += width * 2) {
            const middle = @min(start + width, count);
            const end = @min(middle + width, count);
            var left = start;
            var right = middle;
            var output = start;
            while (left < middle and right < end) {
                const source = if (low[left] <= low[right]) left else right;
                scratch_low[output] = low[source];
                scratch_high[output] = high[source];
                if (source == left) left += 1 else right += 1;
                output += 1;
            }
            while (left < middle) : (left += 1) { scratch_low[output] = low[left]; scratch_high[output] = high[left]; output += 1; }
            while (right < end) : (right += 1) { scratch_low[output] = low[right]; scratch_high[output] = high[right]; output += 1; }
            for (start..end) |index| { low[index] = scratch_low[index]; high[index] = scratch_high[index]; }
        }
        if (width > count / 2) break;
    }
}

fn binaryInsert(values: [*]i64, length: *usize, item: i64) void {
    var low: usize = 0;
    var high = length.*;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (values[middle] < item) low = middle + 1 else high = middle;
    }
    var index = length.*;
    while (index > low) : (index -= 1) values[index] = values[index - 1];
    values[low] = item;
    length.* += 1;
}

export fn merge_insertion_sort(values: [*]i64, length: usize) void {
    if (length > MAX_VALUES) return;
    var pair_low: [MAX_PAIRS]i64 = undefined;
    var pair_high: [MAX_PAIRS]i64 = undefined;
    var scratch_low: [MAX_PAIRS]i64 = undefined;
    var scratch_high: [MAX_PAIRS]i64 = undefined;
    var chain: [MAX_VALUES]i64 = undefined;
    const pair_count = length / 2;
    for (0..pair_count) |pair| {
        const first = values[pair * 2];
        const second = values[pair * 2 + 1];
        if (first <= second) { pair_low[pair] = first; pair_high[pair] = second; }
        else { pair_low[pair] = second; pair_high[pair] = first; }
    }
    sortPairs(&pair_low, &pair_high, &scratch_low, &scratch_high, pair_count);
    var chain_length: usize = 0;
    for (0..pair_count) |pair| { chain[chain_length] = pair_low[pair]; chain_length += 1; }
    if (pair_count > 0) { chain[chain_length] = pair_high[pair_count - 1]; chain_length += 1; }
    if (length % 2 != 0) binaryInsert(&chain, &chain_length, values[length - 1]);
    for (0..pair_count) |pair| {
        if (pair + 1 < pair_count) binaryInsert(&chain, &chain_length, pair_high[pair]);
    }
    for (0..length) |index| values[index] = chain[index];
}
