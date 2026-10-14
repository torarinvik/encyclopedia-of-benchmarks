const MAX_VALUES = 1024;

export fn merge_sort_nr(values: [*]i64, length: usize) void {
    if (length > MAX_VALUES) return;
    var scratch: [MAX_VALUES]i64 = undefined;
    var width: usize = 1;
    while (width < length) : (width *= 2) {
        var start: usize = 0;
        while (start < length) : (start += width * 2) {
            var middle = start + width;
            if (middle > length) middle = length;
            var end_index = middle + width;
            if (end_index > length) end_index = length;
            var left = start;
            var right = middle;
            var output = start;
            while (left < middle and right < end_index) {
                if (values[left] <= values[right]) {
                    scratch[output] = values[left];
                    left += 1;
                } else {
                    scratch[output] = values[right];
                    right += 1;
                }
                output += 1;
            }
            while (left < middle) : (left += 1) {
                scratch[output] = values[left];
                output += 1;
            }
            while (right < end_index) : (right += 1) {
                scratch[output] = values[right];
                output += 1;
            }
        }
        for (0..length) |index| {
            values[index] = scratch[index];
        }
    }
}
