module substring;

const usz MAX_TEXT_LENGTH = 128;
const long MAX_REQUESTED_COUNT = 64;
const long CHECKSUM_BASE = 300000;

fn long substring(long* values, usz length) @export("substring") {
    if (values == null || length < 2 || length > MAX_TEXT_LENGTH + 2) return -1;
    usz text_length = length - 2;
    long start = values[0], requested = values[1];
    if (start < 0 || start > (long)text_length || requested < 0 || requested > MAX_REQUESTED_COUNT) return -1;
    for (usz i = 0; i < text_length; i++) if (values[i + 2] < 1 || values[i + 2] > 127) return -1;
    usz remaining = text_length - (usz)start;
    usz count = (usz)requested;
    if (count == 0 && remaining > 0) count = 1;
    if (count > remaining) count = remaining;
    long checksum = 0;
    for (usz i = 0; i < count; i++) checksum += (long)(i + 1) * values[(usz)start + i + 2];
    return (long)count * CHECKSUM_BASE + checksum;
}
