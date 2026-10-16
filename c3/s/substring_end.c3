module substring_end;

const usz MAX_TEXT_LENGTH = 128;
const long CHECKSUM_BASE = 1100000;

fn long substring_end(long* values, usz length) @export("substring_end") {
    if (values == null || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    usz text_length = length - 1;
    long start = values[0];
    if (start < 0 || start > (long)text_length) return -1;
    for (usz i = 0; i < text_length; i++) if (values[i + 1] < 1 || values[i + 1] > 127) return -1;
    usz count = text_length - (usz)start;
    long checksum = 0;
    for (usz i = 0; i < count; i++) checksum += (long)(i + 1) * values[(usz)start + i + 1];
    return (long)count * CHECKSUM_BASE + checksum;
}
