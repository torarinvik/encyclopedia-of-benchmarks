/// Port of TheAlgorithms/Java IterativeTernarySearch interval updates.
export fn iterative_ternary_search(packed: [*]const i64, length: usize) i64 {
    if (length < 2) return -1;
    const input = packed[0..length];
    const target = input[0];
    const array = input[1..];
    if (array.len == 1) return if (array[0] == target) 0 else -1;

    var left: usize = 0;
    var right = array.len - 1;
    while (right > left) {
        if (array[left] == target) return @intCast(left);
        if (array[right] == target) return @intCast(right);
        const left_third = left + (right - left) / 3 + 1;
        const right_third = right - (right - left) / 3 - 1;
        if (array[left_third] <= target) {
            left = left_third;
        } else {
            right = right_third;
        }
    }
    return -1;
}
