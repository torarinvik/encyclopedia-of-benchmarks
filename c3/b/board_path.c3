module board_path;

fn long board_path(long* input, usz length) @export("board_path") {
    if (input == null || length != 2) return -1;
    long start = input[0];
    long end = input[1];
    if (start < 0 || end < 0 || start > 30 || end > 30 || start > end) return -1;
    long[31] ways;
    ways[(int)end] = 1;
    for (int i = (int)end - 1; i >= (int)start; i--) {
        for (int die = 1; die <= 6 && i + die <= (int)end; die++) ways[i] += ways[i + die];
    }
    return ways[(int)start];
}
