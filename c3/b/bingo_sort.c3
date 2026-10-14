module bingo_sort;

const MAX_VALUES = 1024;

fn void bingo_sort(long* values, usz length) @export("bingo_sort") {
    if (length > MAX_VALUES || length < 2) return;
    long bingo = values[0];
    for (usz index = 1; index < length; index++) {
        if (values[index] < bingo) bingo = values[index];
    }
    usz next_position = 0;
    while (next_position < length) {
        bool has_next = false;
        long next_bingo = 0;
        for (usz index = next_position; index < length; index++) {
            if (values[index] == bingo) {
                long temporary = values[index];
                values[index] = values[next_position];
                values[next_position] = temporary;
                next_position++;
            } else if (!has_next || values[index] < next_bingo) {
                next_bingo = values[index];
                has_next = true;
            }
        }
        if (next_position == length) break;
        bingo = next_bingo;
    }
}
