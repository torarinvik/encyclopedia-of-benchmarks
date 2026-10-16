export fn problem15(grid_size: i64) i64 {
    if (grid_size < 0 or grid_size > 20) return -1;
    var paths: i64 = 1;
    var step: i64 = 1;
    while (step <= grid_size) : (step += 1) {
        paths = @divTrunc(paths * (grid_size + step), step);
    }
    return paths;
}
