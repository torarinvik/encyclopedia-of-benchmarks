module perfect_cube;

// Test whether a signed value is an exact integer cube.
fn long perfect_cube(long value) @export("perfect_cube")
{
    if (value < -1000000000000L || value > 1000000000000L) return -1;
    ulong target = (ulong)(value < 0 ? -value : value);
    if (target < 2) return 1;
    ulong root_limit = target <= 1000 ? 10 : target <= 1000000 ? 100 : target <= 1000000000 ? 1000 : 10000;
    ulong low = 1;
    ulong high = target / 2 < root_limit ? target / 2 : root_limit;
    while (low <= high) {
        ulong middle = (low + high) >> 1;
        ulong cube = middle * middle * middle;
        if (cube == target) return 1;
        if (cube < target) {
            if (middle == high) return 0;
            low = middle + 1;
        } else {
            if (middle == low) return 0;
            high = middle - 1;
        }
    }
    return 0;
}
