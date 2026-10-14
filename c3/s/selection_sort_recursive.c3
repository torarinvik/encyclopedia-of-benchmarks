module selection_sort_recursive;

fn usz minimum_index(long* values, usz start, usz end)
{
    if (start + 1 >= end) return start;
    usz minimum = minimum_index(values, start + 1, end);
    if (values[start] < values[minimum]) return start;
    return minimum;
}

fn void selection_sort_range(long* values, usz start, usz length)
{
    if (start + 1 >= length) return;
    usz minimum = minimum_index(values, start, length);
    if (minimum != start) {
        long temporary = values[start];
        values[start] = values[minimum];
        values[minimum] = temporary;
    }
    selection_sort_range(values, start + 1, length);
}

fn void selection_sort_recursive(long* values, usz length) @export("selection_sort_recursive")
{
    selection_sort_range(values, 0, length);
}
