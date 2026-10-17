package md2_digest

import "core:c"

MD2_S :: [256]u8{
    41,46,67,201,162,216,124,1,61,54,84,161,236,240,6,19,98,167,5,243,192,199,115,140,152,147,43,217,188,76,130,202,
    30,155,87,60,253,212,224,22,103,66,111,24,138,23,229,18,190,78,196,214,218,158,222,73,160,251,245,142,187,47,238,122,
    169,104,121,145,21,178,7,63,148,194,16,137,11,34,95,33,128,127,93,154,90,144,50,39,53,62,204,231,191,247,151,3,
    255,25,48,179,72,165,181,209,215,94,146,42,172,86,170,198,79,184,56,210,150,164,125,182,118,252,107,226,156,116,4,241,
    69,157,112,89,100,113,135,32,134,91,207,101,230,45,168,2,27,96,37,173,174,176,185,246,28,70,97,105,52,64,126,15,
    85,71,163,35,221,81,175,58,195,92,249,206,186,197,234,38,44,83,13,110,133,40,132,9,211,223,205,244,65,129,77,82,
    106,220,55,200,108,193,171,250,36,225,123,8,12,189,177,74,120,136,149,139,227,99,232,109,233,203,213,254,59,0,29,57,
    242,239,183,14,102,88,208,228,166,119,114,248,235,117,75,10,49,68,80,180,143,237,31,26,219,153,141,51,159,17,131,20,
}

@(export)
md2_digest :: proc "c" (input: [^]f64, length: c.size_t,
        output: [^]f64, capacity: c.size_t) -> i64 {
    if length > 63 || (length > 0 && input == nil) do return -1
    count := int(length)
    bytes: [64]u8
    for index := 0; index < count; index += 1 {
        value := input[index]
        if value != value || value < 0.0 || value > 255.0 || value != f64(u8(value)) do return -1
        bytes[index] = u8(value)
    }
    if output == nil || capacity < 16 do return -2

    padding_length := 16 - count % 16
    padded_length := count + padding_length
    for index := count; index < padded_length; index += 1 do bytes[index] = u8(padding_length)
    checksum: [16]u8
    last: u8 = 0
    for offset := 0; offset < padded_length; offset += 16 {
        for index := 0; index < 16; index += 1 {
            checksum[index] ^= MD2_S[bytes[offset + index] ^ last]
            last = checksum[index]
        }
    }

    state: [48]u8
    for offset := 0; offset <= padded_length; offset += 16 {
        for index := 0; index < 16; index += 1 {
            value := checksum[index]
            if offset < padded_length do value = bytes[offset + index]
            state[index + 16] = value
            state[index + 32] = state[index] ^ value
        }
        temporary: u8 = 0
        for round := 0; round < 18; round += 1 {
            for index := 0; index < 48; index += 1 {
                state[index] ^= MD2_S[temporary]
                temporary = state[index]
            }
            temporary = u8((u16(temporary) + u16(round)) & 255)
        }
    }
    for index := 0; index < 16; index += 1 do output[index] = f64(state[index])
    return 16
}
