fn flip_prefix(values: []i64, last_index: usize) void {
    var first: usize = 0;
    var last = last_index;
    while (first < last) {
        const temporary = values[first];
        values[first] = values[last];
        values[last] = temporary;
        first += 1;
        last -= 1;
    }
}

/// Pancake sort using prefix reversals for the shared sorting contract.
export fn pancake_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    const slice = values[0..length];
    var prefix = length;
    while (prefix > 1) : (prefix -= 1) {
        var maximum: usize = 0;
        var probe: usize = 1;
        while (probe < prefix) : (probe += 1) {
            if (slice[probe] > slice[maximum]) maximum = probe;
        }
        if (maximum != prefix - 1) {
            flip_prefix(slice, maximum);
            flip_prefix(slice, prefix - 1);
        }
    }
}
