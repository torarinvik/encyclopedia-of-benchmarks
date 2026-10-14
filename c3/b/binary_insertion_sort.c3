module binary_insertion_sort;

fn void binary_insertion_sort(long* values, usz length) @export("binary_insertion_sort")
{
    for (usz index = 1; index < length; index++) {
        long key = values[index];
        usz low = 0;
        usz high = index;
        while (low < high) {
            usz middle = low + (high - low) / 2;
            if (values[middle] <= key) low = middle + 1;
            else high = middle;
        }
        usz position = index;
        while (position > low) {
            values[position] = values[position - 1];
            position--;
        }
        values[low] = key;
    }
}
