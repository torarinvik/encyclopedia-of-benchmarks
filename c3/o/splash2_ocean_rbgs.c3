module splash2_ocean_rbgs;

const usz MAX_CELLS = 64;
const usz MAX_INPUT = 132;

fn long splash2_ocean_rbgs(double* input, usz input_length, double* output,
                           usz output_capacity) @export("splash2_ocean_rbgs") {
    if (input == null || input_length < 3 || input_length > MAX_INPUT) return -1;
    for (usz i = 0; i < input_length; i++) if (input[i] != input[i]) return -1;
    double side_value = input[0];
    if (side_value != 4.0 && side_value != 6.0 && side_value != 8.0) return -1;
    usz side = (usz)side_value;
    usz cells = side * side;
    if (input_length != 3 + 2 * cells) return -1;
    double eigenvalue_squared = input[1], spacing = input[2];
    if (eigenvalue_squared < 0.0 || eigenvalue_squared > 2.0 ||
        spacing < 0.125 || spacing > 1.0) return -1;
    double factor = 4.0 - eigenvalue_squared * spacing * spacing;
    if (factor <= 0.0) return -1;

    double[MAX_CELLS] grid = zeroed;
    double[MAX_CELLS] rhs = zeroed;
    for (usz i = 0; i < cells; i++) {
        grid[i] = input[3 + i];
        rhs[i] = input[3 + cells + i];
        if (grid[i] < -8.0 || grid[i] > 8.0 || rhs[i] < -8.0 || rhs[i] > 8.0)
            return -1;
    }
    usz needed = 1 + cells;
    if (output == null || output_capacity < needed) return -2;

    double max_change = 0.0;
    for (usz color = 0; color < 2; color++) {
        for (usz row = 1; row + 1 < side; row++) {
            for (usz column = 1; column + 1 < side; column++) {
                if ((row + column) % 2 != color) continue;
                usz index = row * side + column;
                double neighbors = grid[index + 1] + grid[index - 1] +
                    grid[index - side] + grid[index + side];
                double old_value = grid[index];
                double updated = (neighbors - rhs[index]) / factor;
                double change = old_value > updated ? old_value - updated : updated - old_value;
                if (change > max_change) max_change = change;
                grid[index] = updated;
            }
        }
    }
    output[0] = max_change;
    for (usz i = 0; i < cells; i++) output[i + 1] = grid[i];
    return (long)needed;
}
