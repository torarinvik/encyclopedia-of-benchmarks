module game_of_life;

const long MAX_SIDE = 32;

fn long game_of_life(long* input, usz length, char* output, usz output_capacity)
        @export("game_of_life") {
    if (input == null || length == 0) return -1;
    long side_value = input[0];
    if (side_value < 0 || side_value > MAX_SIDE) return -1;
    usz side = (usz)side_value;
    usz cell_count = side * side;
    if (length != cell_count + 1) return -1;
    for (usz index = 0; index < cell_count; index++) {
        if (input[index + 1] != 0 && input[index + 1] != 1) return -1;
    }
    if (output_capacity < cell_count || (cell_count != 0 && output == null)) return -2;

    for (long row = 0; row < side_value; row++) {
        for (long column = 0; column < side_value; column++) {
            uint neighbors = 0;
            for (long row_delta = -1; row_delta <= 1; row_delta++) {
                for (long column_delta = -1; column_delta <= 1; column_delta++) {
                    if (row_delta == 0 && column_delta == 0) continue;
                    long neighbor_row = row + row_delta;
                    long neighbor_column = column + column_delta;
                    if (neighbor_row >= 0 && neighbor_row < side_value &&
                        neighbor_column >= 0 && neighbor_column < side_value &&
                        input[1 + (usz)neighbor_row * side + (usz)neighbor_column] == 1) {
                        neighbors++;
                    }
                }
            }
            usz index = (usz)row * side + (usz)column;
            bool alive = input[index + 1] == 1;
            output[index] = (char)(alive ? (neighbors == 2 || neighbors == 3)
                                         : (neighbors == 3));
        }
    }
    return (long)cell_count;
}
