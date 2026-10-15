module unique_paths;

// Count right-and-down paths with one row of dynamic programming.
fn long unique_paths(ulong rows, ulong columns) @export("unique_paths")
{
    if (rows == 0 || columns == 0 || rows > 34 || columns > 34) return -1;
    ulong width = rows < columns ? rows : columns;
    ulong height = rows < columns ? columns : rows;
    long[34] paths;
    for (ulong column = 0; column < width; column++) paths[column] = 1;
    for (ulong row = 1; row < height; row++) {
        for (ulong column = 1; column < width; column++) {
            paths[column] += paths[column - 1];
        }
    }
    return paths[width - 1];
}
