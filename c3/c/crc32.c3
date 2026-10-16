module crc32;
const usz MAX_LENGTH = 100001;
fn long crc32(long* values, usz length) @export("crc32") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    long crc = 4294967295;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value < 0 || value > 255) return -1;
        crc = crc ^ value;
        for (int bit = 0; bit < 8; bit++) {
            if ((crc & 1) != 0) crc = (crc >> 1) ^ 3988292384;
            else crc = crc >> 1;
        }
    }
    return crc ^ 4294967295;
}
