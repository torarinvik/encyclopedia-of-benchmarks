module quick_sort_3;

fn void quick_sort_3_range(long* values, usz low_value, usz high_value)
{
    usz low = low_value;
    usz high = high_value;
    while (high - low > 1) {
        long pivot = values[high - 1];
        usz less = low;
        usz scan = low;
        usz greater = high;
        while (scan < greater) {
            if (values[scan] < pivot) {
                long temporary = values[less];
                values[less] = values[scan];
                values[scan] = temporary;
                less++;
                scan++;
            } else if (values[scan] > pivot) {
                greater--;
                long temporary = values[scan];
                values[scan] = values[greater];
                values[greater] = temporary;
            } else {
                scan++;
            }
        }
        if (less - low < high - greater) {
            quick_sort_3_range(values, low, less);
            low = greater;
        } else {
            quick_sort_3_range(values, greater, high);
            high = less;
        }
    }
}

fn void quick_sort_3(long* values, usz length) @export("quick_sort_3")
{
    if (length > 1) quick_sort_3_range(values, 0, length);
}
