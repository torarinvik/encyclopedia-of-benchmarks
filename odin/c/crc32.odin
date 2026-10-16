package crc32
import "core:c"
MAX_LENGTH :: 100_001
POLYNOMIAL :: i64(3_988_292_384)
INITIAL :: i64(4_294_967_295)
@(export)
crc32 :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values == nil) do return -1
    crc := INITIAL
    for index := c.size_t(0); index < length; index += 1 {
        value := values[index]
        if value < 0 || value > 255 do return -1
        crc = crc ^ value
        for bit := 0; bit < 8; bit += 1 {
            if (crc & 1) != 0 do crc = (crc >> 1) ^ POLYNOMIAL
            else do crc = crc >> 1
        }
    }
    return crc ^ INITIAL
}
