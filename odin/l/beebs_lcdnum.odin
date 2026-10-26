package beebs_lcdnum

import "core:c"

INPUT_BYTES :: 5
SEGMENT_MASKS: [16]u8 = {0x00,0x24,0x5D,0x6D,0x2E,0x5D,0x7B,0x25,0x7F,0x6F,0x3F,0x7A,0x53,0x7C,0x5B,0x1B}

@(export)
beebs_lcdnum :: proc "c" (values: [^]i64, length: c.size_t,
                           output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length != INPUT_BYTES do return -1
    for i in 0..<INPUT_BYTES {
        if values[i] < 0 || values[i] > 255 do return -1
    }
    if output == nil || capacity < c.size_t(INPUT_BYTES) do return -2
    for i in 0..<INPUT_BYTES {
        output[i] = SEGMENT_MASKS[int(values[i] & 0x0f)]
    }
    return i64(INPUT_BYTES)
}
