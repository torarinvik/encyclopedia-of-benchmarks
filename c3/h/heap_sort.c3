module heap_sort;

fn void sift_down(long* values, usz root, usz end)
{
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        long temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn void heap_sort(long* values, usz length) @export("heap_sort")
{
    for (usz start = length / 2; start > 0;) {
        start--;
        sift_down(values, start, length);
    }
    for (usz end = length; end > 1;) {
        end--;
        long temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        sift_down(values, 0, end);
    }
}
