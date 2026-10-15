module minimum_path_cost_in_grid;

const INF_COST = 1000000000;

fn long minimum_path_cost_in_grid(long* input, usz length) @export("minimum_path_cost_in_grid")
{
    if (input == null || length < 2 || input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > 32) return -1;
    usz rows = (usz)input[0];
    usz columns = (usz)input[1];
    usz cells = rows * columns;
    usz move_offset = 2 + cells;
    if (length != move_offset + cells * columns) return -1;
    for (usz index = 0; index < cells; index++) {
        if (input[2 + index] < 0 || input[2 + index] >= (long)cells) return -1;
    }
    for (usz index = 0; index < cells * columns; index++) {
        if (input[move_offset + index] < 1 || input[move_offset + index] > 100) return -1;
    }
    long[32] costs;
    long[32] next_costs;
    for (usz column = 0; column < columns; column++) costs[column] = 0;
    for (usz row = 0; row + 1 < rows; row++) {
        for (usz target = 0; target < columns; target++) next_costs[target] = INF_COST;
        for (usz column = 0; column < columns; column++) {
            usz value = (usz)input[2 + row * columns + column];
            long base = costs[column] + (long)value;
            for (usz target = 0; target < columns; target++) {
                long candidate = base + input[move_offset + value * columns + target];
                if (candidate < next_costs[target]) next_costs[target] = candidate;
            }
        }
        for (usz column = 0; column < columns; column++) costs[column] = next_costs[column];
    }
    long minimum = INF_COST;
    usz last_row = 2 + (rows - 1) * columns;
    for (usz column = 0; column < columns; column++) {
        long candidate = costs[column] + input[last_row + column];
        if (candidate < minimum) minimum = candidate;
    }
    return minimum;
}
