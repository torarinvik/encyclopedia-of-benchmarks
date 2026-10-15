module square_root;

// Newton square root using binary64 arithmetic and a portable initial estimate.
fn double square_root(double value) @export("square_root")
{
    if (value == 0.0) return 0.0;
    double estimate = value >= 1.0 ? value : 1.0;
    for (int iteration = 0; iteration < 1100; iteration++) {
        double next = 0.5 * estimate + 0.5 * (value / estimate);
        if (next >= estimate) return estimate;
        estimate = next;
    }
    return estimate;
}
