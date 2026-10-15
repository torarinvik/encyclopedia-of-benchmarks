module newton_square_root;

extern fn double log2(double value);
extern fn double ceil(double value);

fn long newton_square_root(long value) @export("newton_square_root")
{
    if (value < 0 || value > 4611686018427387903L) return -1L;
    if (value == 0) return 0L;

    int bit_length = (int)ceil(log2((double)value));
    long root = 1L << (bit_length / 2);
    while (!(value >= root * root && value <= root * root + root + root)) {
        root += value / root;
        root /= 2;
    }
    return root;
}
