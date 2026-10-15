export fn boyer_moore_majority_vote(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 256) return -1;
    var candidate: i64 = 0;
    var balance: usize = 0;
    for (0..length) |index| {
        const value = values[index];
        if (balance == 0) candidate = value;
        if (value == candidate) balance += 1 else balance -= 1;
    }
    var occurrences: usize = 0;
    for (0..length) |index| {
        if (values[index] == candidate) occurrences += 1;
    }
    return if (occurrences > length / 2) candidate else -1;
}
