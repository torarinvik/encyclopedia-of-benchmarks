fn bst_shape(start: usize, ending: usize, heap_index: usize) u64 {
    if (start >= ending) return 0;
    const middle = start + (ending - start - 1) / 2;
    return (@as(u64, 1) << @intCast(heap_index))
        | bst_shape(start, middle, 2 * heap_index + 1)
        | bst_shape(middle + 1, ending, 2 * heap_index + 2);
}

export fn bst_from_sorted_array(input: ?[*]const i64, length: usize) i64 {
    if (length > 15 or (length != 0 and input == null)) return -1;
    if (length != 0) {
        const values = input.?;
        for (0..length) |index| {
            const value = values[index];
            if (value < -2147483648 or value > 2147483647) return -1;
            if (index > 0 and values[index - 1] >= value) return -1;
        }
    }
    return @intCast(bst_shape(0, length, 0));
}
