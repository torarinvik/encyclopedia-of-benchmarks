module scimark2_sor;

fn long scimark2_sor(long* input, usz length) @export("scimark2_sor") {
    if (input == null || length < 3 || length > 67) return -1;
    if (input[0] < 2 || input[0] > 8 || input[1] < 2 || input[1] > 8 || input[2] < 0 || input[2] > 8) return -1;
    int rows = (int)input[0];
    int cols = (int)input[1];
    int iterations = (int)input[2];
    if (length != (usz)(3 + rows * cols)) return -1;
    long[64] grid;
    for (int i = 0; i < rows * cols; i++) {
        long value = input[3 + (usz)i];
        if (value < -1000 || value > 1000) return -1;
        grid[i] = value;
    }
    for (int pass = 0; pass < iterations; pass++) {
        for (int row = 1; row < rows - 1; row++) {
            for (int col = 1; col < cols - 1; col++) {
                int index = row * cols + col;
                long neighbors = grid[index - cols] + grid[index + cols] + grid[index - 1] + grid[index + 1];
                long numerator = 1250 * neighbors - 1000 * grid[index];
                grid[index] = numerator / 4000;
            }
        }
    }
    long checksum = 0;
    for (int i = 0; i < rows * cols; i++) checksum += (long)(i + 1) * grid[i];
    return checksum;
}
