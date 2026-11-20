module jsort;

fn void sift_down_min(long* values, usz root, usz end) {
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child + 1] < values[child]) child++;
        if (values[root] <= values[child]) break;
        long temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn void sift_down_max(long* values, usz root, usz end) {
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child + 1] > values[child]) child++;
        if (values[root] >= values[child]) break;
        long temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn void reverse_values(long* values, usz length) {
    for (usz left = 0; left < length / 2; left++) {
        usz right = length - 1 - left;
        long temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
    }
}

fn void jsort(long* values, usz length) @export("jsort") {
    if (values == null || length < 2) return;
    for (usz start = length / 2; start > 0;) {
        start--;
        sift_down_min(values, start, length);
    }
    reverse_values(values, length);
    for (usz start = length / 2; start > 0;) {
        start--;
        sift_down_max(values, start, length);
    }
    reverse_values(values, length);

    for (usz index = 1; index < length; index++) {
        long key = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > key) {
            values[position] = values[position - 1];
            position--;
        }
        values[position] = key;
    }
}
