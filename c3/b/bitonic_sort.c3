module bitonic_sort;

fn void bitonic_compare(long* values, usz left, usz right, bool ascending)
{
    if ((ascending && values[left] > values[right]) || (!ascending && values[left] < values[right])) {
        long temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
    }
}

fn void bitonic_merge(long* values, usz low, usz length, bool ascending)
{
    if (length < 2) return;
    usz half = length / 2;
    for (usz index = low; index < low + half; index++) {
        bitonic_compare(values, index, index + half, ascending);
    }
    bitonic_merge(values, low, half, ascending);
    bitonic_merge(values, low + half, half, ascending);
}

fn void bitonic_sort_range(long* values, usz low, usz length, bool ascending)
{
    if (length < 2) return;
    usz half = length / 2;
    bitonic_sort_range(values, low, half, true);
    bitonic_sort_range(values, low + half, half, false);
    bitonic_merge(values, low, length, ascending);
}

fn void bitonic_sort(long* values, usz length) @export("bitonic_sort")
{
    if (length < 2) return;
    bitonic_sort_range(values, 0, length, true);
}
