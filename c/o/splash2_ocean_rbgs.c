#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 8u
#define MAX_CELLS (MAX_SIDE * MAX_SIDE)
#define MAX_INPUT 132u
#define MAX_OUTPUT (1u + MAX_CELLS)

int64_t splash2_ocean_rbgs(const double *input, size_t input_length,
                           double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > MAX_INPUT) return -1;
    for (size_t i = 0; i < input_length; ++i) {
        if (!isfinite(input[i])) return -1;
    }
    const double side_value = input[0];
    if (side_value != 4.0 && side_value != 6.0 && side_value != 8.0) return -1;
    const size_t side = (size_t)side_value;
    const size_t cells = side * side;
    if (input_length != 3 + 2 * cells) return -1;
    const double eigenvalue_squared = input[1];
    const double spacing = input[2];
    if (eigenvalue_squared < 0.0 || eigenvalue_squared > 2.0 ||
        spacing < 0.125 || spacing > 1.0) return -1;
    const double factor = 4.0 - eigenvalue_squared * spacing * spacing;
    if (!isfinite(factor) || factor <= 0.0) return -1;

    double grid[MAX_CELLS] = {0.0};
    double rhs[MAX_CELLS] = {0.0};
    for (size_t i = 0; i < cells; ++i) {
        grid[i] = input[3 + i];
        rhs[i] = input[3 + cells + i];
        if (grid[i] < -8.0 || grid[i] > 8.0 || rhs[i] < -8.0 || rhs[i] > 8.0)
            return -1;
    }
    const size_t needed = 1 + cells;
    if (output == NULL || output_capacity < needed) return -2;

    double max_change = 0.0;
    for (size_t color = 0; color < 2; ++color) {
        for (size_t row = 1; row + 1 < side; ++row) {
            for (size_t column = 1; column + 1 < side; ++column) {
                if ((row + column) % 2 != color) continue;
                const size_t index = row * side + column;
                const double neighbors = grid[index + 1] + grid[index - 1] +
                                         grid[index - side] + grid[index + side];
                const double updated = (neighbors - rhs[index]) / factor;
                const double change = fabs(grid[index] - updated);
                if (change > max_change) max_change = change;
                grid[index] = updated;
            }
        }
    }
    output[0] = max_change;
    for (size_t i = 0; i < cells; ++i) output[i + 1] = grid[i];
    return (int64_t)needed;
}
