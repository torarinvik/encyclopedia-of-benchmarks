const MAX_VALUES = 1024;

export fn bingo_sort(values: [*]i64, length: usize) void {
    if (length > MAX_VALUES or length < 2) return;
    var bingo = values[0];
    for (1..length) |index| {
        if (values[index] < bingo) bingo = values[index];
    }
    var next_position: usize = 0;
    while (next_position < length) {
        var has_next = false;
        var next_bingo: i64 = 0;
        var index = next_position;
        while (index < length) : (index += 1) {
            if (values[index] == bingo) {
                const temporary = values[index];
                values[index] = values[next_position];
                values[next_position] = temporary;
                next_position += 1;
            } else if (!has_next or values[index] < next_bingo) {
                next_bingo = values[index];
                has_next = true;
            }
        }
        if (next_position == length) break;
        bingo = next_bingo;
    }
}
