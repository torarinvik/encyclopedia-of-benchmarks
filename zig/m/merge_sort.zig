/// Stable bottom-up merge sort using caller-provided scratch storage.
export fn merge_sort(values: [*]i64, scratch: [*]i64, length: usize) void {
    var width: usize = 1;
    while (width < length) {
        var low: usize = 0;
        while (low < length) {
            const middle = @min(low + width, length);
            const high = @min(middle + width, length);
            var left = low;
            var right = middle;
            var output = low;
            while (left < middle and right < high) {
                if (values[left] <= values[right]) {
                    scratch[output] = values[left];
                    left += 1;
                } else {
                    scratch[output] = values[right];
                    right += 1;
                }
                output += 1;
            }
            while (left < middle) {
                scratch[output] = values[left];
                left += 1;
                output += 1;
            }
            while (right < high) {
                scratch[output] = values[right];
                right += 1;
                output += 1;
            }
            @memcpy(values[low..high], scratch[low..high]);
            low = high;
        }
        if (width > length / 2) break;
        width *= 2;
    }
}
