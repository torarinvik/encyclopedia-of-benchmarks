module hamming_distance;

// Portable Hamming distance over two unsigned 64-bit values.
fn long hamming_distance(ulong left, ulong right) @export("hamming_distance")
{
    long count = 0;
    while (left != 0 || right != 0) {
        if ((left & 1) != (right & 1)) count++;
        left = left >> 1;
        right = right >> 1;
    }
    return count;
}
