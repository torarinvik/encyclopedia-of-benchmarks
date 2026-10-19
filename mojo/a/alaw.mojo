@export("alaw_encode")
fn alaw_encode(input: Int64) abi("C") -> Int64:
    if input < -32768 or input > 32767:
        return -1
    var sample = Int32(input)
    var sign: Int32 = 0
    if sample < 0:
        sign = 128
        sample = -sample - 1
    var segment: Int32 = 7
    var mask: Int32 = 16384
    while (sample & mask) == 0 and segment > 0:
        segment -= 1
        mask >>= 1
    var shift = 4
    if segment != 0:
        shift = segment + 3
    let quant = (sample >> shift) & 15
    return Int64((sign | (segment << 4) | quant) ^ 0xD5)
