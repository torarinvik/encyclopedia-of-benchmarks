module stooge_sort;

fn void stooge_sort_range(long* values, usz low, usz high)
{
    usz length = high - low;
    if (length < 2) return;
    if (values[low] > values[high - 1]) {
        long temporary = values[low];
        values[low] = values[high - 1];
        values[high - 1] = temporary;
    }
    if (length > 2) {
        usz third = length / 3;
        stooge_sort_range(values, low, high - third);
        stooge_sort_range(values, low + third, high);
        stooge_sort_range(values, low, high - third);
    }
}

fn void stooge_sort(long* values, usz length) @export("stooge_sort")
{
    if (length > 1) stooge_sort_range(values, 0, length);
}
