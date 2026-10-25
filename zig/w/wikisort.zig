const cache_capacity: usize = 512;
const run_size: usize = 16;
const maximum_length: usize = 2048;

fn reverseRange(values: [*]i64, first_value: usize, last_value: usize) void {
    var first = first_value;
    var last = last_value;
    while (first < last) {
        last -= 1;
        if (first >= last) break;
        const item = values[first];
        values[first] = values[last];
        values[last] = item;
        first += 1;
    }
}

fn insertionSort(values: [*]i64, first: usize, last: usize) void {
    var index = first + 1;
    while (index < last) : (index += 1) {
        const item = values[index];
        var position = index;
        while (position > first and item < values[position - 1]) {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = item;
    }
}

fn rotateAdjacent(values: [*]i64, scratch: [*]i64, first: usize, middle: usize, last: usize, cache_size: usize) void {
    const left_length = middle - first;
    const right_length = last - middle;
    if (left_length == 0 or right_length == 0) return;
    if (left_length <= right_length and left_length <= cache_size) {
        @memcpy(scratch[0..left_length], values[first..middle]);
        var index: usize = 0;
        while (index < right_length) : (index += 1) values[first + index] = values[middle + index];
        @memcpy(values[first + right_length .. last], scratch[0..left_length]);
        return;
    }
    if (right_length < left_length and right_length <= cache_size) {
        @memcpy(scratch[0..right_length], values[middle..last]);
        var index = left_length;
        while (index > 0) {
            index -= 1;
            values[first + right_length + index] = values[first + index];
        }
        @memcpy(values[first .. first + right_length], scratch[0..right_length]);
        return;
    }
    reverseRange(values, first, middle);
    reverseRange(values, middle, last);
    reverseRange(values, first, last);
}

fn mergeFromCache(values: [*]i64, scratch: [*]i64, first: usize, middle: usize, last: usize) void {
    const left_length = middle - first;
    @memcpy(scratch[0..left_length], values[first..middle]);
    var left: usize = 0;
    var right = middle;
    var output = first;
    while (left < left_length and right < last) {
        if (scratch[left] <= values[right]) {
            values[output] = scratch[left];
            left += 1;
        } else {
            values[output] = values[right];
            right += 1;
        }
        output += 1;
    }
    while (left < left_length) {
        values[output] = scratch[left];
        left += 1;
        output += 1;
    }
}

fn blockRotationMerge(values: [*]i64, scratch: [*]i64, first: usize, middle_value: usize, last: usize, cache_size: usize) void {
    const total = last - first;
    var block_size: usize = 1;
    while (block_size + 1 <= total / (block_size + 1)) block_size += 1;
    var middle = middle_value;
    var left = first;
    while (left < middle and middle < last) {
        if (values[left] <= values[middle]) {
            const boundary_value = values[middle];
            var low = left;
            var high = middle;
            while (low < high) {
                const probe = low + (high - low) / 2;
                if (values[probe] <= boundary_value) low = probe + 1 else high = probe;
            }
            left = low;
        } else {
            const key = values[left];
            var low = middle;
            var high = last;
            while (low < high) {
                const probe = low + (high - low) / 2;
                if (values[probe] < key) low = probe + 1 else high = probe;
            }
            var block_end = low;
            if (block_end - middle > block_size) block_end = middle + block_size;
            const moved = block_end - middle;
            if (moved == 0) {
                left += 1;
            } else {
                rotateAdjacent(values, scratch, left, middle, block_end, cache_size);
                left += moved;
                middle += moved;
            }
        }
    }
}

export fn wikisort(values: [*]i64, scratch: [*]i64, length: usize) void {
    if (length < 2 or length > maximum_length) return;
    const cache_size = @min(length, cache_capacity);
    if (length <= 32) {
        insertionSort(values, 0, length);
        return;
    }
    var start: usize = 0;
    while (start < length) : (start += run_size) {
        insertionSort(values, start, @min(start + run_size, length));
    }
    var width: usize = run_size;
    while (width < length) {
        var first: usize = 0;
        while (first < length) {
            const middle = @min(first + width, length);
            const last = @min(middle + width, length);
            if (middle < last and values[middle] < values[middle - 1]) {
                if (values[last - 1] < values[first]) {
                    rotateAdjacent(values, scratch, first, middle, last, cache_size);
                } else if (middle - first <= cache_size) {
                    mergeFromCache(values, scratch, first, middle, last);
                } else {
                    blockRotationMerge(values, scratch, first, middle, last, cache_size);
                }
            }
            first = last;
        }
        if (width > length / 2) break;
        width *= 2;
    }
}
