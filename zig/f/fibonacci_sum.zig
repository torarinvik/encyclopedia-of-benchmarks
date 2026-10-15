/// Inclusive Fibonacci range sum for the shared unsigned pair ABI.
export fn fibonacci_sum(start: u64, end_value: u64) i64 {
    if (end_value > 90 or start > end_value) return -1;
    const lower_index = start + 1;
    const upper_index = end_value + 2;
    var previous: i64 = 0;
    var current: i64 = 1;
    var lower: i64 = 0;
    var lower_current: i64 = 1;
    var i: u64 = 1;
    while (i < upper_index) : (i += 1) {
        const next = previous + current;
        previous = current;
        current = next;
        if (i < lower_index) {
            const lower_next = lower + lower_current;
            lower = lower_current;
            lower_current = lower_next;
        }
    }
    return current - lower_current;
}
