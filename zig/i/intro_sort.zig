fn swap_i64(values: []i64, left: usize, right: usize) void {
    const temporary = values[left];
    values[left] = values[right];
    values[right] = temporary;
}

fn insertion_sort_range(values: []i64, low: usize, high: usize) void {
    var index = low + 1;
    while (index < high) : (index += 1) {
        const key = values[index];
        var cursor = index;
        while (cursor > low and values[cursor - 1] > key) : (cursor -= 1) {
            values[cursor] = values[cursor - 1];
        }
        values[cursor] = key;
    }
}

fn sift_down(values: []i64, start: usize, count: usize, root_start: usize) void {
    var root = root_start;
    while (root < count / 2) {
        var child = root * 2 + 1;
        if (child + 1 < count and values[start + child] < values[start + child + 1]) child += 1;
        if (values[start + root] >= values[start + child]) return;
        swap_i64(values, start + root, start + child);
        root = child;
    }
}

fn heap_sort_range(values: []i64, low: usize, count: usize) void {
    var parent = count / 2;
    while (parent > 0) {
        parent -= 1;
        sift_down(values, low, count, parent);
    }
    var ending = count;
    while (ending > 1) {
        ending -= 1;
        swap_i64(values, low, low + ending);
        sift_down(values, low, ending, 0);
    }
}

fn partition_range(values: []i64, low: usize, high: usize) usize {
    const last = high - 1;
    const pivot_index = low + (high - low) / 2;
    swap_i64(values, pivot_index, last);
    const pivot = values[last];
    var boundary = low;
    for (low..last) |probe| {
        if (values[probe] <= pivot) {
            swap_i64(values, boundary, probe);
            boundary += 1;
        }
    }
    swap_i64(values, boundary, last);
    return boundary;
}

fn intro_sort_range(values: []i64, low: usize, high: usize, depth: usize) void {
    const count = high - low;
    if (count <= 16) {
        insertion_sort_range(values, low, high);
        return;
    }
    if (depth == 0) {
        heap_sort_range(values, low, count);
        return;
    }
    const pivot = partition_range(values, low, high);
    intro_sort_range(values, low, pivot, depth - 1);
    intro_sort_range(values, pivot + 1, high, depth - 1);
}

fn depth_limit(length: usize) usize {
    var remaining = length;
    var logarithm: usize = 0;
    while (remaining > 1) {
        remaining >>= 1;
        logarithm += 1;
    }
    return logarithm * 2;
}

/// Introsort with quicksort partitioning, a heapsort depth fallback, and insertion cutoff.
export fn intro_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    intro_sort_range(values[0..length], 0, length, depth_limit(length));
}
