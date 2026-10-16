module substring_st_char;

const usz MAX_TEXT_LENGTH = 128;
const long MAX_REQUESTED_COUNT = 64;
const long CHECKSUM_BASE = 300000;

fn long substring_st_char(long* values, usz length) @export("substring_st_char") {
    if (values == null || length < 2 || length > MAX_TEXT_LENGTH + 2) return -1;
    long target = values[0], requested = values[1];
    usz text_length = length - 2;
    if (target < 1 || target > 127 || requested < 0 || requested > MAX_REQUESTED_COUNT) return -1;
    for (usz i = 0; i < text_length; i++) if (values[i + 2] < 1 || values[i + 2] > 127) return -1;
    usz start = 0;
    while (start < text_length && values[start + 2] != target) start++;
    if (start == text_length) return -1;
    usz remaining = text_length - start;
    usz count = (usz)requested;
    if (count == 0) count = 1;
    if (count > remaining) count = remaining;
    long checksum = 0;
    for (usz i = 0; i < count; i++) checksum += (long)(i + 1) * values[start + i + 2];
    return (long)count * CHECKSUM_BASE + checksum;
}
