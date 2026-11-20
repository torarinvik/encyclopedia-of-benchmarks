fn sift_down_min(values: [*]i64, root_value: usize, end: usize) void {
    var root = root_value;
    while (root < end / 2) {
        var child = root * 2 + 1;
        if (child + 1 < end and values[child + 1] < values[child]) child += 1;
        if (values[root] <= values[child]) break;
        const temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn sift_down_max(values: [*]i64, root_value: usize, end: usize) void {
    var root = root_value;
    while (root < end / 2) {
        var child = root * 2 + 1;
        if (child + 1 < end and values[child + 1] > values[child]) child += 1;
        if (values[root] >= values[child]) break;
        const temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn reverse_values(values: [*]i64, length: usize) void {
    for (0..length / 2) |left| {
        const right = length - 1 - left;
        const temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
    }
}

export fn jsort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    var start = length / 2;
    while (start > 0) {
        start -= 1;
        sift_down_min(values, start, length);
    }

    reverse_values(values, length);
    start = length / 2;
    while (start > 0) {
        start -= 1;
        sift_down_max(values, start, length);
    }
    reverse_values(values, length);

    var index: usize = 1;
    while (index < length) : (index += 1) {
        const key = values[index];
        var position = index;
        while (position > 0 and values[position - 1] > key) {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = key;
    }
}
