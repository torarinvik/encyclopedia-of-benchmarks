/// Backward recursive linear search over a bounded integer array.
fn search_from_end(items: [*]const i64, count: usize, target: i64) i64 {
    if (count == 0) return -1;
    if (items[count - 1] == target) return @intCast(count - 1);
    return search_from_end(items, count - 1, target);
}

export fn recursive_linear_search(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 67) return -1;
    const count_value = values[0];
    const target = values[1];
    if (count_value < 1 or count_value > 64) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;
    return search_from_end(values + 2, count, target);
}
