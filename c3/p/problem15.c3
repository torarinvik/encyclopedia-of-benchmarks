module problem15;

fn long problem15(long grid_size) @export("problem15") {
    if (grid_size < 0 || grid_size > 20) return -1;
    long paths = 1;
    for (long step = 1; step <= grid_size; step++) {
        paths = paths * (grid_size + step) / step;
    }
    return paths;
}
