package alaw

@(export)
alaw_encode :: proc "c" (input: i64) -> i64 {
    if input < -32768 || input > 32767 do return -1
    sample := i32(input)
    sign: i32 = 0
    magnitude := sample
    if sample < 0 {
        sign = 0x80
        magnitude = -sample - 1
    }
    segment: i32 = 7
    mask: i32 = 0x4000
    for (magnitude & mask) == 0 && segment > 0 {
        segment -= 1
        mask >>= 1
    }
    shift := 4
    if segment != 0 do shift = segment + 3
    quantization := (magnitude >> shift) & 0x0f
    return i64((sign | (segment << 4) | quantization) ^ 0xD5)
}
