/// Compare the linked-list value sequence from both ends without mutation.
export fn palindrome_linked_list(values: [*]const i64, length: usize) i64 {
    if (length > 100000) return -1;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 9) return -1;
    }

    var left: usize = 0;
    var right = length;
    while (left < right) {
        right -= 1;
        if (values[left] != values[right]) return 0;
        left += 1;
    }
    return 1;
}
