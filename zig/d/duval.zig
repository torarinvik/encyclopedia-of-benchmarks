/// Least cyclic shift index using Duval's linear-time scan.
export fn duval(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    if (length == 0) return 0;
    for (values[0..length]) |value| {
        if (value < 0 or value > 127) return -1;
    }

    var i: usize = 0;
    var answer: usize = 0;
    while (i < length) {
        answer = i;
        var j = i + 1;
        var k = i;
        while (j < 2 * length and values[j % length] >= values[k % length]) {
            if (values[k % length] < values[j % length]) k = i else k += 1;
            j += 1;
        }
        while (i <= k) i += j - k;
    }
    return @intCast(answer);
}
