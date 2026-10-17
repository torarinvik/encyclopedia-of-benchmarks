fn medianOfThree(a: i64, b: i64, c: i64) i64 {
    if (a <= b) {
        if (b <= c) return b;
        if (a <= c) return c;
        return a;
    }
    if (b >= c) return b;
    if (a >= c) return c;
    return a;
}

fn partitionRange(values: [*]i64, left: usize, right: usize) usize {
    const middle = left + (right - left) / 2;
    const pivot = medianOfThree(values[left], values[middle], values[right]);
    var nleft = left;
    var nright = right;
    while (true) {
        while (values[nleft] < pivot) : (nleft += 1) {}
        while (values[nright] > pivot) : (nright -= 1) {}
        if (nleft >= nright) return nright;
        const temporary = values[nleft];
        values[nleft] = values[nright];
        values[nright] = temporary;
        nleft += 1;
        nright -= 1;
    }
}

fn sortRange(values: [*]i64, left: usize, right: usize) void {
    if (left >= right) return;
    const pivot = partitionRange(values, left, right);
    sortRange(values, left, pivot);
    sortRange(values, pivot + 1, right);
}

export fn median_of_three_quick_sorter(values: [*]i64, length: usize) void {
    if (length > 1) sortRange(values, 0, length - 1);
}
