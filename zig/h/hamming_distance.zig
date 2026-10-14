/// Portable Hamming distance over two unsigned 64-bit values.
export fn hamming_distance(left_value: u64, right_value: u64) i64 {
    var left = left_value;
    var right = right_value;
    var count: i64 = 0;
    while (left != 0 or right != 0) {
        if ((left & 1) != (right & 1)) count += 1;
        left >>= 1;
        right >>= 1;
    }
    return count;
}
