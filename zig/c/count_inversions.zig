/// Count strict inversions with bottom-up merge sort.
export fn count_inversions(values: [*]const i64, length: usize) i64 {
    const max_length = 4096;
    if (length > max_length) return -1;
    if (length < 2) return 0;

    var source: [max_length]i64 = undefined;
    var scratch: [max_length]i64 = undefined;
    for (0..length) |i| source[i] = values[i];

    var inversions: i64 = 0;
    var width: usize = 1;
    while (width < length) : (width *= 2) {
        var low: usize = 0;
        while (low < length) {
            const middle = @min(low + width, length);
            const high = @min(middle + width, length);
            var left = low;
            var right = middle;
            var output = low;
            while (left < middle and right < high) {
                if (source[left] <= source[right]) {
                    scratch[output] = source[left];
                    left += 1;
                } else {
                    scratch[output] = source[right];
                    right += 1;
                    inversions += @intCast(middle - left);
                }
                output += 1;
            }
            while (left < middle) : (left += 1) {
                scratch[output] = source[left];
                output += 1;
            }
            while (right < high) : (right += 1) {
                scratch[output] = source[right];
                output += 1;
            }
            low = high;
        }
        @memcpy(source[0..length], scratch[0..length]);
    }
    return inversions;
}
