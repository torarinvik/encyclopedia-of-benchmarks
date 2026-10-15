/// Find the greatest h for which at least h citations are >= h.
export fn h_index(citations: [*]const i64, length: usize) i64 {
    if (length > 5000) return -1;
    for (0..length) |index| {
        if (citations[index] < 0 or citations[index] > 1000) return -1;
    }

    var low: usize = 0;
    var high: usize = length;
    if (high > 1000) high = 1000;
    while (low < high) {
        const middle = low + (high - low + 1) / 2;
        var qualifying: usize = 0;
        for (0..length) |index| {
            if (@as(u64, @intCast(citations[index])) >= middle) {
                qualifying += 1;
                if (qualifying >= middle) break;
            }
        }
        if (qualifying >= middle) low = middle else high = middle - 1;
    }
    return @intCast(low);
}
