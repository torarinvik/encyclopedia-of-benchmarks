module insertion_sort;

fn void insertion_sort(long* values, usz length) @export("insertion_sort")
{
    for (usz index = 1; index < length; index++) {
        long key = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > key) {
            values[position] = values[position - 1];
            position--;
        }
        values[position] = key;
    }
}
