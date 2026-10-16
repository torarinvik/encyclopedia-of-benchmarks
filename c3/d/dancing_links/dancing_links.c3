module dancing_links;

// Choose the uncovered column with the fewest compatible rows, then branch on it.
fn void search(usz columns, usz row_count, uint* rows, uint covered, uint selected,
               bool* found, usz* solution_count) {
    uint full_mask = (1u << (uint)columns) - 1u;
    if (covered == full_mask) {
        usz index = (usz)selected;
        if (!found[index]) { found[index] = true; *solution_count = *solution_count + 1; }
        return;
    }
    usz best_column = columns;
    usz best_count = row_count + 1;
    for (usz column = 0; column < columns; column++) {
        uint bit = 1u << (uint)column;
        if ((covered & bit) != 0) continue;
        usz candidates = 0;
        for (usz row = 0; row < row_count; row++)
            if ((rows[row] & bit) != 0 && (rows[row] & covered) == 0) candidates++;
        if (candidates == 0) return;
        if (candidates < best_count) { best_count = candidates; best_column = column; }
    }
    uint bit = 1u << (uint)best_column;
    for (usz row = 0; row < row_count; row++) {
        if ((rows[row] & bit) != 0 && (rows[row] & covered) == 0)
            search(columns, row_count, rows, covered | rows[row], selected | (1u << (uint)row), found, solution_count);
    }
}

fn long dancing_links(long* input, usz length, char* output, usz output_capacity)
        @export("dancing_links") {
    if (input == null || length < 2 || length > 10) return -1;
    long universe_value = input[0];
    long row_count_value = input[1];
    if (universe_value < 1 || universe_value > 8 || row_count_value < 0 || row_count_value > 8 ||
        length != (usz)(row_count_value + 2)) return -1;
    usz columns = (usz)universe_value;
    usz row_count = (usz)row_count_value;
    uint full_mask = (1u << (uint)columns) - 1u;
    uint[8] rows = {};
    for (usz row = 0; row < row_count; row++) {
        long value = input[row + 2];
        if (value <= 0 || ((uint)value & ~full_mask) != 0) return -1;
        rows[row] = (uint)value;
    }
    bool[256] found = {};
    usz solution_count = 0;
    search(columns, row_count, &rows[0], 0, 0, &found[0], &solution_count);
    if (output_capacity < solution_count || (solution_count != 0 && output == null)) return -2;
    usz position = 0;
    for (usz selection = 0; selection < 256; selection++) {
        if (found[selection]) { output[position] = (char)selection; position++; }
    }
    return (long)solution_count;
}
