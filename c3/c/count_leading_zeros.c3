module count_leading_zeros;

import std::bits;

fn long count_leading_zeros(long value) @export("count_leading_zeros")
{
    if (value < -2147483648 || value > 2147483647) return -1;
    return (long)((uint)value).clz();
}
