module shrink_shell_sort;

fn void shrink_shell_sort(long* values, usz length) @export("shrink_shell_sort") {
    usz gap = length;
    while (gap > 1) {
        gap = (usz)((double)gap / 1.3);
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
