const MAX_VALUES = 1024;

fn siftUp(values: [*]i64, index_value: usize) void {
    var index = index_value;
    while (index > 0) {
        const parent = (index - 1) / 2;
        if (values[parent] >= values[index]) break;
        const temporary = values[parent];
        values[parent] = values[index];
        values[index] = temporary;
        index = parent;
    }
}

fn siftDown(values: [*]i64, size: usize) void {
    var root: usize = 0;
    while (root < size / 2) {
        const left = root * 2 + 1;
        var largest = left;
        const right = left + 1;
        if (right < size and values[right] > values[left]) largest = right;
        if (values[root] >= values[largest]) break;
        const temporary = values[root];
        values[root] = values[largest];
        values[largest] = temporary;
        root = largest;
    }
}

export fn heap_sort_2(values: [*]i64, length: usize) void {
    if (length > MAX_VALUES) return;
    for (0..length) |index| siftUp(values, index);
    var size = length;
    while (size > 1) : (size -= 1) {
        const maximum = values[0];
        values[0] = values[size - 1];
        values[size - 1] = maximum;
        siftDown(values, size - 1);
    }
}
