module floor;

// Floor for bounded finite binary64 inputs, correcting truncation below zero.
fn double floor(double value) @export("floor")
{
    if (value < -1000000.0 || value > 1000000.0) return -1.0;
    long result = (long)value;
    if (value < (double)result) result--;
    return (double)result;
}
