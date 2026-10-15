module binary_length;

extern fn double log2(double value);
extern fn double floor(double value);

fn long binary_length(long value) @export("binary_length")
{
    if (value <= 0 || value > 2147483647) return -1;
    return (long)(floor(log2((double)value)) + 1.0);
}
