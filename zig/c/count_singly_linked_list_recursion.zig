fn count_recursive(input: [*]const i64, index: usize, remaining: usize) i64 {
    if (remaining == 0) return 0;
    const payload = input[index];
    if (payload < -2147483648 or payload > 2147483647) return -1;
    const tail_count = count_recursive(input, index + 1, remaining - 1);
    if (tail_count < 0) return -1;
    return 1 + tail_count;
}

/// Recursively count a finite singly linked chain represented in node order.
export fn count_singly_linked_list_recursion(input: [*]const i64, length: usize) i64 {
    if (length < 1 or input[0] < 0 or input[0] > 64) return -1;
    const count: usize = @intCast(input[0]);
    if (length != count + 1) return -1;
    return count_recursive(input, 1, count);
}
