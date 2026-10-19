module five11;

const MAX_INPUT: usz = 13523;
const MAX_PARSEABLE_INPUT: usz = 13524;
const MAX_PACKETS: long = 451;

fn read_bits(values: long*, length: usz, bit_offset: usz, width: usz) -> long {
    usz bit_length = length * 8;
    if (bit_offset > bit_length || width > bit_length - bit_offset) return -1;
    usz byte_offset = bit_offset >> 3;
    usz start = bit_offset & 7;
    usz byte_count = (start + width + 7) >> 3;
    uint window = 0;
    for (usz index = 0; index < byte_count; index++)
        window = (window << 8) | (uint)values[byte_offset + index];
    usz shift = byte_count * 8 - start - width;
    uint mask = (1u << width) - 1;
    return (long)((window >> shift) & mask);
}

fn decode_sum(values: long*, length: usz) -> long {
    long packet_count = read_bits(values, length, 0, 16);
    if (packet_count < 0 || packet_count > MAX_PACKETS) return -1;
    usz bit_offset = 16;
    long total = 0;
    for (long packet = 0; packet < packet_count; packet++) {
        long channels = read_bits(values, length, bit_offset, 5);
        if (channels < 0) return -1;
        bit_offset += 5;
        for (long channel = 0; channel < channels; channel++) {
            long value = read_bits(values, length, bit_offset, 11);
            if (value < 0) return -1;
            total += value;
            bit_offset += 11;
        }
        usz packet_bits = 5 + 11 * channels.usz();
        bit_offset += (8 - (packet_bits & 7)) & 7;
        if (bit_offset > length * 8) return -1;
    }
    return total;
}

fn long five11(long* values, usz length) @export("five11") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_INPUT || length > MAX_INPUT) return -1;
    for (usz index = 0; index < length; index++)
        if (values[index] < 0 || values[index] > 255) return -1;
    long result = 0;
    for (usz repetition = 0; repetition < 10000; repetition++) {
        result = decode_sum(values, length);
        if (result < 0) return -1;
    }
    return result;
}
