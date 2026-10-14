module quick_sort;

fn usz partition(long* values, usz low, usz high)
{
    long pivot = values[high - 1];
    usz boundary = low;
    for (usz scan = low; scan < high - 1; scan++) {
        if (values[scan] <= pivot) {
            long temporary = values[boundary];
            values[boundary] = values[scan];
            values[scan] = temporary;
            boundary++;
        }
    }
    long temporary = values[boundary];
    values[boundary] = values[high - 1];
    values[high - 1] = temporary;
    return boundary;
}

fn void quick_sort_range(long* values, usz low_value, usz high_value)
{
    usz low = low_value;
    usz high = high_value;
    while (high - low > 1) {
        usz pivot = partition(values, low, high);
        usz right_start = pivot + 1;
        if (pivot - low < high - right_start) {
            quick_sort_range(values, low, pivot);
            low = right_start;
        } else {
            quick_sort_range(values, right_start, high);
            high = pivot;
        }
    }
}

fn void quick_sort(long* values, usz length) @export("quick_sort")
{
    if (length > 1) quick_sort_range(values, 0, length);
}
