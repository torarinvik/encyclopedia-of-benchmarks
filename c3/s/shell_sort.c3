module shell_sort;

fn void shell_sort(long* values, usz length) @export("shell_sort")
{
    for (usz gap = length / 2; gap > 0; gap /= 2) {
        for (usz index = gap; index < length; index++) {
            long key = values[index];
            usz position = index;
            while (position >= gap && values[position - gap] > key) {
                values[position] = values[position - gap];
                position -= gap;
            }
            values[position] = key;
        }
    }
}
