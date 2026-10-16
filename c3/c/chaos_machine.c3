module chaos_machine;
extern fn double floor(double value);
extern fn void* memcpy(void* destination, void* source, usz length);
fn double fraction_one(double value) { return value - floor(value); }
fn double round_ten(double value) {
    if (value <= 0.0) return 0.0;
    ulong bits;
    memcpy(&bits, &value, 8);
    ulong exponent = (bits >> 52) & 0x7FF;
    if (exponent == 0) return 0.0;
    ulong mantissa = (1ul << 52) | (bits & ((1ul << 52) - 1));
    ulong low_product = (mantissa & 0xFFFFFFFFul) * 9765625ul;
    ulong high_product = (mantissa >> 32) * 9765625ul;
    ulong shifted_high = high_product << 32;
    ulong low = shifted_high + low_product;
    ulong carry = 0;
    if (low < shifted_high) carry = 1;
    ulong high = (high_product >> 32) + carry;
    int shift = 1065 - (int)exponent;
    if (shift > 77) return 0.0;
    ulong rounded;
    int relation;
    if (shift < 64) {
        rounded = (high << (64 - shift)) | (low >> shift);
        ulong remainder = low & ((1ul << shift) - 1);
        ulong half = 1ul << (shift - 1);
        relation = remainder > half ? 1 : remainder < half ? -1 : 0;
    } else if (shift == 64) {
        rounded = high;
        ulong half = 1ul << 63;
        relation = low > half ? 1 : low < half ? -1 : 0;
    } else {
        int upper_bits = shift - 64;
        rounded = high >> upper_bits;
        ulong remainder_high = high & ((1ul << upper_bits) - 1);
        ulong half_high = 1ul << (upper_bits - 1);
        relation = remainder_high > half_high || (remainder_high == half_high && low != 0)
            ? 1 : remainder_high < half_high ? -1 : 0;
    }
    if (relation > 0 || (relation == 0 && (rounded & 1) != 0)) rounded += 1;
    return (double)rounded / 10000000000.0;
}
fn uint pull(ulong* machine_time, double* buffer, double* params) {
    usz key = (usz)(*machine_time % 5);
    for (usz step = 0; step < 3; step++) {
        double rate = params[key];
        double value = buffer[key];
        buffer[key] = round_ten(rate * value * (1.0 - value));
        params[key] = fraction_one((double)(*machine_time) * 0.01 + rate * 1.01) + 3.0;
    }
    ulong x = (ulong)(buffer[(key + 2) % 5] * 10000000000.0);
    ulong y = (ulong)(buffer[(key + 3) % 5] * 10000000000.0);
    *machine_time += 1;
    x ^= y >> 13; y ^= x << 17; x ^= y >> 5;
    return (uint)(x & 0xFFFFFFFF);
}
fn long chaos_machine(long* values, usz length, char* output, usz output_capacity) @export("chaos_machine") {
    if (values == null || length < 2 || length > 66) return -1;
    if (values[0] < 0 || values[0] > 64 || length != (usz)values[0] + 2) return -1;
    usz seed_count = (usz)values[0];
    long pull_input = values[length - 1];
    if (pull_input < 0 || pull_input > 64) return -1;
    for (usz index = 0; index < seed_count; index++) {
        if (values[index + 1] < 0 || values[index + 1] > 1000000) return -1;
    }
    usz pull_count = (usz)pull_input;
    usz required = 4 * pull_count;
    if (required > output_capacity || (required != 0 && output == null)) return -2;
    double[5] buffer = {0.33, 0.44, 0.55, 0.44, 0.33};
    double[5] params = {0.0, 0.0, 0.0, 0.0, 0.0};
    ulong machine_time = 0;
    for (usz seed_index = 0; seed_index < seed_count; seed_index++) {
        double seed = (double)values[seed_index + 1];
        for (usz key = 0; key < 5; key++) {
            if (buffer[key] == 0.0) return -1;
            double evolution = seed / buffer[key];
            double value = fraction_one(buffer[(key + 1) % 5] + evolution);
            double rate = fraction_one(params[key] + evolution) + 3.0;
            buffer[key] = round_ten(rate * value * (1.0 - value));
            params[key] = rate;
        }
        machine_time += 1;
    }
    for (usz index = 0; index < pull_count; index++) {
        uint result = pull(&machine_time, &buffer[0], &params[0]);
        for (usz byte = 0; byte < 4; byte++) output[4 * index + byte] = (char)(result >> (8 * byte));
    }
    return (long)required;
}
