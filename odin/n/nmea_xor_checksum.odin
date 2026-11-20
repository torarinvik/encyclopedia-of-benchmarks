package nmea_xor_checksum

import "core:c"

@(export)
nmea_xor_checksum :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length == 0 || length > 78 do return -1
    payload_length := values[0]
    if payload_length < 0 || payload_length > 76 ||
       length != c.size_t(payload_length + 1) do return -1
    checksum: i64 = 0
    for i := c.size_t(1); i < length; i += 1 {
        byte := values[i]
        if byte < 0 || byte > 127 do return -1
        checksum ^= byte
    }
    return checksum
}
