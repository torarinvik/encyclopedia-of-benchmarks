/// Least cyclic rotation by two-candidate elimination.
export fn minimum_string_representation(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    if (length == 0) return 0;
    for (values[0..length]) |value| {
        if (value < 0 or value > 127) return -1;
    }

    var left: usize = 0;
    var right: usize = 1;
    var matched: usize = 0;
    while (left < length and right < length and matched < length) {
        const a = values[(left + matched) % length];
        const b = values[(right + matched) % length];
        if (a == b) {
            matched += 1;
            continue;
        }
        if (a > b) {
            left += matched + 1;
            if (left == right) left += 1;
        } else {
            right += matched + 1;
            if (left == right) right += 1;
        }
        matched = 0;
    }
    return @intCast(@min(left, right));
}
