/// Return the unique mode of a bounded integer sequence.
export fn average_mode(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 64) return -1;
    for (0..length) |i| {
        if (values[i] < 0 or values[i] > 1000) return -1;
    }

    var mode: i64 = -1;
    var maximum_count: usize = 0;
    var tied = false;
    for (0..length) |i| {
        var seen = false;
        for (0..i) |before| {
            if (values[before] == values[i]) { seen = true; break; }
        }
        if (seen) continue;

        var count: usize = 0;
        for (0..length) |j| {
            if (values[j] == values[i]) count += 1;
        }
        if (count > maximum_count) {
            maximum_count = count;
            mode = values[i];
            tied = false;
        } else if (count == maximum_count) {
            tied = true;
        }
    }
    return if (tied) -1 else mode;
}
