module strange_printer_ii;

const usz MAX_ROWS = 6;
const usz MAX_COLUMNS = 6;
const usz MAX_COLORS = 6;
const usz COLOR_SIDE = 7;

fn long strange_printer_ii(long* input, usz length) @export("strange_printer_ii") {
    if (input == null || length < 2 || length > 39) return -1;
    long rows_value = input[0], columns_value = input[1];
    if (rows_value < 1 || rows_value > (long)MAX_ROWS || columns_value < 1 || columns_value > (long)MAX_COLUMNS) return -1;
    usz rows = (usz)rows_value, columns = (usz)columns_value;
    if (length != 2 + rows * columns) return -1;
    for (usz cell = 0; cell < rows * columns; cell++) {
        if (input[cell + 2] < 1 || input[cell + 2] > (long)MAX_COLORS) return -1;
    }

    long[COLOR_SIDE] first_row, last_row, first_column, last_column, outgoing, indegree, queue;
    for (usz color = 0; color < COLOR_SIDE; color++) {
        first_row[color] = rows_value; last_row[color] = -1;
        first_column[color] = columns_value; last_column[color] = -1;
        outgoing[color] = 0; indegree[color] = 0; queue[color] = 0;
    }
    for (usz row = 0; row < rows; row++) {
        for (usz column = 0; column < columns; column++) {
            long color = input[2 + row * columns + column];
            if ((long)row < first_row[color]) first_row[color] = (long)row;
            if ((long)row > last_row[color]) last_row[color] = (long)row;
            if ((long)column < first_column[color]) first_column[color] = (long)column;
            if ((long)column > last_column[color]) last_column[color] = (long)column;
        }
    }

    long present_count = 0;
    for (usz color = 1; color <= MAX_COLORS; color++) {
        if (last_row[color] < 0) continue;
        present_count++;
        for (long row = first_row[color]; row <= last_row[color]; row++) {
            for (long column = first_column[color]; column <= last_column[color]; column++) {
                long covered = input[2 + (usz)row * columns + (usz)column];
                long bit = 1L << covered;
                if (covered != (long)color && (outgoing[color] & bit) == 0) {
                    outgoing[color] |= bit;
                    indegree[covered]++;
                }
            }
        }
    }
    usz head = 0, tail = 0;
    for (usz color = 1; color <= MAX_COLORS; color++) {
        if (last_row[color] >= 0 && indegree[color] == 0) queue[tail++] = (long)color;
    }
    long processed = 0;
    while (head < tail) {
        long color = queue[head++];
        processed++;
        for (usz later = 1; later <= MAX_COLORS; later++) {
            if ((outgoing[color] & (1L << later)) != 0) {
                indegree[later]--;
                if (indegree[later] == 0) queue[tail++] = (long)later;
            }
        }
    }
    return processed == present_count ? 1 : 0;
}
