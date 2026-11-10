module hamming_distance;

import std::bits;

fn long hamming_distance(ulong left, ulong right) @export("hamming_distance")
{
    return (long)(left ^ right).popcount();
}
