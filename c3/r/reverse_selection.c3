module reverse_selection;

fn void reverse_selection(long* values, usz length) @export("reverse_selection")
{
    if (length < 2) return;
    for (usz start = 0; start + 1 < length; start++) {
        usz minimum = start;
        for (usz scan = start + 1; scan < length; scan++) {
            if (values[scan] < values[minimum]) minimum = scan;
        }
        usz left = start;
        usz right = minimum;
        while (left < right) {
            long temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            left++;
            right--;
        }
    }
}
