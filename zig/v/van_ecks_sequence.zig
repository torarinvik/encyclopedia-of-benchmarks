export fn van_ecks_sequence(position: i64) i64 {
    if (position < 1 or position > 16) return -1;
    var last_seen: [17]i64 = [_]i64{0} ** 17;
    var previous: i64 = 0;
    var current: i64 = 2;
    while (current <= position) : (current += 1) {
        var next: i64 = 0;
        const previous_index: usize = @intCast(previous);
        if (last_seen[previous_index] != 0) {
            next = current - last_seen[previous_index];
        }
        last_seen[previous_index] = current;
        previous = next;
    }
    return previous;
}
