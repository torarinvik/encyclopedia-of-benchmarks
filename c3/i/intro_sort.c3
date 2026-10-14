module intro_sort;

fn void swap_i64(long* values, usz left, usz right)
{
    long temporary = values[left];
    values[left] = values[right];
    values[right] = temporary;
}

fn void insertion_sort_range(long* values, usz low, usz high)
{
    for (usz index = low + 1; index < high; index++) {
        long key = values[index];
        usz cursor = index;
        while (cursor > low && values[cursor - 1] > key) {
            values[cursor] = values[cursor - 1];
            cursor--;
        }
        values[cursor] = key;
    }
}

fn void sift_down(long* values, usz start, usz count, usz root)
{
    while (root < count / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < count && values[start + child] < values[start + child + 1]) child++;
        if (values[start + root] >= values[start + child]) return;
        swap_i64(values, start + root, start + child);
        root = child;
    }
}

fn void heap_sort_range(long* values, usz low, usz count)
{
    usz parent = count / 2;
    while (parent > 0) {
        parent--;
        sift_down(values, low, count, parent);
    }
    usz end = count;
    while (end > 1) {
        end--;
        swap_i64(values, low, low + end);
        sift_down(values, low, end, 0);
    }
}

fn usz partition_range(long* values, usz low, usz high)
{
    usz last = high - 1;
    usz pivot_index = low + (high - low) / 2;
    swap_i64(values, pivot_index, last);
    long pivot = values[last];
    usz boundary = low;
    for (usz probe = low; probe < last; probe++) {
        if (values[probe] <= pivot) {
            swap_i64(values, boundary, probe);
            boundary++;
        }
    }
    swap_i64(values, boundary, last);
    return boundary;
}

fn void intro_sort_range(long* values, usz low, usz high, usz depth)
{
    usz count = high - low;
    if (count <= 16) {
        insertion_sort_range(values, low, high);
        return;
    }
    if (depth == 0) {
        heap_sort_range(values, low, count);
        return;
    }
    usz pivot = partition_range(values, low, high);
    intro_sort_range(values, low, pivot, depth - 1);
    intro_sort_range(values, pivot + 1, high, depth - 1);
}

fn usz depth_limit(usz length)
{
    usz logarithm = 0;
    while (length > 1) {
        length = length / 2;
        logarithm++;
    }
    return logarithm * 2;
}

fn void intro_sort(long* values, usz length) @export("intro_sort")
{
    if (length < 2) return;
    intro_sort_range(values, 0, length, depth_limit(length));
}
