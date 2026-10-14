module circle_sort;

fn bool circle_pass(long* values, usz low, usz high)
{
    usz length = high - low;
    if (length < 2) return false;
    bool swapped = false;
    usz left = low;
    usz right = high - 1;
    while (left < right) {
        if (values[left] > values[right]) {
            long temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            swapped = true;
        }
        left++;
        right--;
    }
    if (length % 2 != 0 && left == right && right + 1 < high && values[right + 1] < values[right]) {
        long temporary = values[right];
        values[right] = values[right + 1];
        values[right + 1] = temporary;
        swapped = true;
    }
    usz split = low + length / 2 + length % 2;
    bool left_swapped = circle_pass(values, low, split);
    bool right_swapped = circle_pass(values, split, high);
    return swapped || left_swapped || right_swapped;
}

fn void circle_sort(long* values, usz length) @export("circle_sort")
{
    while (length > 1 && circle_pass(values, 0, length)) { }
}
