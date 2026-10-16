module substring_minus;

const usz MAX_TEXT_LENGTH = 128;
const long CHECKSUM_BASE = 1100000;

fn long substring_minus(long* values, usz length) @export("substring_minus") {
    if (values == null || length < 1 || length > MAX_TEXT_LENGTH) return -1;
    for (usz i = 0; i < length; i++) if (values[i] < 1 || values[i] > 127) return -1;
    usz count = length - 1;
    long checksum = 0;
    for (usz i = 0; i < count; i++) checksum += (long)(i + 1) * values[i];
    return (long)count * CHECKSUM_BASE + checksum;
}
