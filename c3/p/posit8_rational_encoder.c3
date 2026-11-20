module posit8_rational_encoder;

const usz MAX_COUNT = 32;
const usz MAX_WORDS = 66;

fn long positive_units(uchar code) {
    long cursor = 6;
    long regime_bit = (code >> 6) & 1;
    long run = 0;
    while (cursor >= 0 && (((code >> (usz)cursor) & 1) == (uchar)regime_bit)) {
        run += 1;
        cursor -= 1;
    }
    long regime = regime_bit != 0 ? run - 1 : -run;
    if (cursor >= 0) cursor -= 1;
    long exponent = 0;
    for (usz i = 0; i < 2; i += 1) {
        exponent <<= 1;
        if (cursor >= 0) {
            exponent |= (long)((code >> (usz)cursor) & 1);
            cursor -= 1;
        }
    }
    long width = cursor + 1;
    long fraction = width > 0 ? (long)(code & ((1 << (usz)width) - 1)) : 0;
    long significand = (1 << (usz)width) + fraction;
    long shift = 4 * regime + exponent + 24 - width;
    return significand << (usz)shift;
}

fn int compare_ratio_to_unit(ulong scaled, ulong denominator, ulong unit) {
    ulong quotient = scaled / denominator;
    ulong remainder = scaled % denominator;
    if (quotient < unit) return -1;
    if (quotient > unit) return 1;
    return remainder == 0 ? 0 : 1;
}

fn uchar encode_one(long numerator, long denominator) {
    if (numerator == 0) return 0;
    bool negative = numerator < 0;
    ulong magnitude = (ulong)(negative ? -numerator : numerator);
    ulong scaled = magnitude << 24;
    uchar chosen;
    if (compare_ratio_to_unit(scaled, (ulong)denominator, 1) <= 0) {
        chosen = 1;
    } else if (compare_ratio_to_unit(scaled, (ulong)denominator, (ulong)positive_units(127)) >= 0) {
        chosen = 127;
    } else {
        long low = 1, high = 127;
        while (low < high) {
            long middle = low + (high - low) / 2;
            ulong value = (ulong)positive_units((uchar)middle);
            if (compare_ratio_to_unit(scaled, (ulong)denominator, value) > 0) low = middle + 1;
            else high = middle;
        }
        long upper = low, lower = upper - 1;
        ulong midpoint = (ulong)positive_units((uchar)lower) + (ulong)positive_units((uchar)upper);
        int midpoint_comparison = compare_ratio_to_unit(scaled << 1, (ulong)denominator, midpoint);
        if (midpoint_comparison < 0) chosen = (uchar)lower;
        else if (midpoint_comparison > 0) chosen = (uchar)upper;
        else chosen = (uchar)((lower & 1) == 0 ? lower : upper);
    }
    return negative ? (uchar)(0 - chosen) : chosen;
}

fn long posit8_rational_encoder(long* input, usz length, uchar* output, usz capacity)
    @export("posit8_rational_encoder") {
    if (input == null || length < 1 || length > MAX_WORDS) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > (long)MAX_COUNT || length != 1 + (usz)raw_count * 2) return -1;
    usz count = (usz)raw_count;
    for (usz i = 0; i < count; i += 1) {
        long numerator = input[1 + 2 * i], denominator = input[2 + 2 * i];
        if (numerator < -2147483648 || numerator > 2147483648 || denominator < 1 || denominator > 2147483648) return -1;
    }
    if (output == null || capacity < count) return -2;
    uchar[32] staged;
    for (usz i = 0; i < count; i += 1) staged[i] = encode_one(input[1 + 2 * i], input[2 + 2 * i]);
    for (usz i = 0; i < count; i += 1) output[i] = staged[i];
    return (long)count;
}
