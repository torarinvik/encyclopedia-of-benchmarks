module partition_sort;

fn usz partition_range(long* values, usz low, usz high)
{
    long pivot = values[low];
    usz left = low;
    usz right = high;
    while (true) {
        while (values[left] < pivot) left++;
        while (values[right] > pivot) right--;
        if (left >= right) return right;
        long temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
        left++;
        right--;
    }
}

fn void partition_sort_range(long* values, usz low, usz high)
{
    if (low < high) {
        usz split = partition_range(values, low, high);
        partition_sort_range(values, low, split);
        partition_sort_range(values, split + 1, high);
    }
}

fn void partition_sort(long* values, usz length) @export("partition_sort")
{
    if (length > 1) partition_sort_range(values, 0, length - 1);
}
