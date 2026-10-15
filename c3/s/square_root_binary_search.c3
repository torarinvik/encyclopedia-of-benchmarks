module square_root_binary_search;

// Floor square root by binary search, with division avoiding square overflow.
fn long square_root_binary_search(long value) @export("square_root_binary_search")
{
    if (value < 0) return -1;
    if (value < 2) return value;
    long low = 1;
    long high = value;
    long answer = 0;
    while (low <= high) {
        long middle = low + (high - low) / 2;
        if (middle <= value / middle) {
            answer = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return answer;
}
