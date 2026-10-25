module rodinia_pathfinder;

// Bounded row-wise minimum-cost path through a grid.
fn long rodinia_pathfinder(long* input, usz length) @export("rodinia_pathfinder") {
    if (input == null || length < 4 || length > 1027) return -1;
    if (input[0] < 1 || input[0] > 32 || input[1] < 1 || input[1] > 32 ||
        input[2] < 1 || input[2] > 4) return -1;
    usz cols = (usz)input[0], rows = (usz)input[1], height = (usz)input[2];
    usz cells = cols * rows;
    if (length != 3 + cells) return -1;
    for (usz i = 0; i < cells; i++) if (input[3 + i] < 0 || input[3 + i] > 9) return -1;

    long[32] previous, current;
    for (usz col = 0; col < cols; col++) previous[col] = input[3 + col];
    for (usz first = 1; first < rows; first += height) {
        usz steps = rows - first;
        if (steps > height) steps = height;
        for (usz step = 0; step < steps; step++) {
            usz row = first + step;
            for (usz col = 0; col < cols; col++) {
                long best = previous[col];
                if (col > 0 && previous[col - 1] < best) best = previous[col - 1];
                if (col + 1 < cols && previous[col + 1] < best) best = previous[col + 1];
                current[col] = best + input[3 + row * cols + col];
            }
            for (usz col = 0; col < cols; col++) previous[col] = current[col];
        }
    }
    long answer = previous[0];
    for (usz col = 1; col < cols; col++) if (previous[col] < answer) answer = previous[col];
    return answer;
}
