module number_of_ways_select_buildings;

const MAX_LENGTH = 4096;

fn long number_of_ways_to_select_buildings(long* values, usz length) @export("number_of_ways_to_select_buildings") {
    if (length == 0) return 0;
    if (values == null || length > MAX_LENGTH) return -1;
    ulong different_bits = 0;
    uint zeros = 0;
    uint ones = 0;
    uint zero_one = 0;
    uint one_zero = 0;
    ulong ways = 0;
    for (usz index = 0; index < length; ++index) {
        ulong byte = (ulong)values[index] ^ 48;
        different_bits |= byte;
        bool is_one = (byte & 1) != 0;
        ways += (ulong)(is_one ? one_zero : zero_one);
        zero_one += is_one ? zeros : 0;
        one_zero += is_one ? 0 : ones;
        zeros += is_one ? 0 : 1;
        ones += is_one ? 1 : 0;
    }
    if (different_bits > 1) return -1;
    return (long)ways;
}
