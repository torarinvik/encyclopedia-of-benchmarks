/// Floor square root by binary search, with division avoiding square overflow.
export fn square_root_binary_search(value: i64) i64 {
    if (value < 0) return -1;
    if (value < 2) return value;
    var low: i64 = 1;
    var high: i64 = value;
    var answer: i64 = 0;
    while (low <= high) {
        const middle = low + @divTrunc(high - low, 2);
        if (middle <= @divTrunc(value, middle)) {
            answer = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return answer;
}
