module nmea_xor_checksum;

fn long nmea_xor_checksum(long* values, usz length) @export("nmea_xor_checksum") {
    if (values == null || length == 0 || length > 78) return -1;
    long payload_length = values[0];
    if (payload_length < 0 || payload_length > 76 ||
        length != (usz)(payload_length + 1)) return -1;
    long checksum = 0;
    for (usz i = 1; i < length; i++) {
        long byte = values[i];
        if (byte < 0 || byte > 127) return -1;
        checksum = checksum ^ byte;
    }
    return checksum;
}
