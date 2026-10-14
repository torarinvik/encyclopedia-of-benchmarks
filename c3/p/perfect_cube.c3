module perfect_cube;

// Test whether a signed value is an exact integer cube.
fn long perfect_cube(long value) @export("perfect_cube")
{
    if (value < -1000000000000L || value > 1000000000000L) return -1;
    long target = value < 0 ? -value : value;
    long low = 0;
    long high = 10000;
    while (low <= high) {
        long middle = low + (high - low) / 2;
        long cube = middle * middle * middle;
        if (cube == target) return 1;
        if (cube < target) { low = middle + 1; }
        else { high = middle - 1; }
    }
    return 0;
}
