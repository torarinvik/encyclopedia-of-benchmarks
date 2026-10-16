/// Sentinel search for the shared mutable-input benchmark contract.
export fn sentinel_search(values: [*]i64, length: usize, target: i64) i64 {
    if (length == 0) return -1;

    const last_index = length - 1;
    const saved_last = values[last_index];
    if (saved_last == target) return @intCast(last_index);

    values[last_index] = target;
    var index: usize = 0;
    while (values[index] != target) : (index += 1) {}
    values[last_index] = saved_last;

    if (index == last_index) return -1;
    return @intCast(index);
}
