module recursive_bubble_sort;

fn void recursive_bubble_sort_range(long* values, usz length)
{
    if (length < 2) return;
    for (usz index = 0; index + 1 < length; index++) {
        if (values[index] > values[index + 1]) {
            long temporary = values[index];
            values[index] = values[index + 1];
            values[index + 1] = temporary;
        }
    }
    recursive_bubble_sort_range(values, length - 1);
}

fn void recursive_bubble_sort(long* values, usz length) @export("recursive_bubble_sort")
{
    recursive_bubble_sort_range(values, length);
}
