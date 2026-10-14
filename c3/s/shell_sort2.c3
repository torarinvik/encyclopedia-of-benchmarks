module shell_sort2;

fn void shell_sort2(long* values, usz length) @export("shell_sort2") {
    usz[8] gaps;
    gaps[0] = 701; gaps[1] = 301; gaps[2] = 132; gaps[3] = 57;
    gaps[4] = 23; gaps[5] = 10; gaps[6] = 4; gaps[7] = 1;
    for (usz gap_index = 0; gap_index < 8; gap_index++) {
        usz gap = gaps[gap_index];
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
