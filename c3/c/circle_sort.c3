module circle_sort;

fn bool circle_sort_range(long* values, usz left_value, usz right_value)
{
    if (left_value >= right_value) return false;

    usz low = left_value;
    usz high = right_value;
    bool swapped = false;
    while (low < high) {
        if (values[low] > values[high]) {
            long temporary = values[low];
            values[low] = values[high];
            values[high] = temporary;
            swapped = true;
        }
        low++;
        high--;
    }
    if (low == high && values[low] > values[high + 1]) {
        long temporary = values[low];
        values[low] = values[high + 1];
        values[high + 1] = temporary;
        swapped = true;
    }

    usz middle = left_value + (right_value - left_value) / 2;
    bool left_swapped = circle_sort_range(values, left_value, middle);
    bool right_swapped = circle_sort_range(values, middle + 1, right_value);
    return swapped || left_swapped || right_swapped;
}

fn void circle_sort(long* values, usz length) @export("circle_sort")
{
    if (length < 2) return;
    while (circle_sort_range(values, 0, length - 1)) {}
}
