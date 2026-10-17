module median_of_three_quick_sorter;

fn long median_of_three(long a, long b, long c) {
    if (a <= b) {
        if (b <= c) return b;
        if (a <= c) return c;
        return a;
    }
    if (b >= c) return b;
    if (a >= c) return c;
    return a;
}

fn usz partition_range(long* values, usz left, usz right) {
    usz middle = left + (right - left) / 2;
    long pivot = median_of_three(values[left], values[middle], values[right]);
    usz nleft = left;
    usz nright = right;
    while (true) {
        while (values[nleft] < pivot) nleft++;
        while (values[nright] > pivot) nright--;
        if (nleft >= nright) return nright;
        long temporary = values[nleft];
        values[nleft] = values[nright];
        values[nright] = temporary;
        nleft++;
        nright--;
    }
}

fn void sort_range(long* values, usz left, usz right) {
    if (left >= right) return;
    usz pivot = partition_range(values, left, right);
    sort_range(values, left, pivot);
    sort_range(values, pivot + 1, right);
}

fn void median_of_three_quick_sorter(long* values, usz length) @export("median_of_three_quick_sorter") {
    if (length > 1) sort_range(values, 0, length - 1);
}
