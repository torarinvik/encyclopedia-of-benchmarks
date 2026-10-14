module heap_sort_2;

const MAX_VALUES = 1024;

fn void sift_up(long* values, usz index) {
    while (index > 0) {
        usz parent = (index - 1) / 2;
        if (values[parent] >= values[index]) break;
        long temporary = values[parent];
        values[parent] = values[index];
        values[index] = temporary;
        index = parent;
    }
}

fn void sift_down(long* values, usz size) {
    usz root = 0;
    while (root < size / 2) {
        usz left = root * 2 + 1;
        usz largest = left;
        usz right = left + 1;
        if (right < size && values[right] > values[left]) largest = right;
        if (values[root] >= values[largest]) break;
        long temporary = values[root];
        values[root] = values[largest];
        values[largest] = temporary;
        root = largest;
    }
}

fn void heap_sort_2(long* values, usz length) @export("heap_sort_2") {
    if (length > MAX_VALUES) return;
    for (usz index = 0; index < length; index++) sift_up(values, index);
    for (usz size = length; size > 1; size--) {
        long maximum = values[0];
        values[0] = values[size - 1];
        values[size - 1] = maximum;
        sift_down(values, size - 1);
    }
}
