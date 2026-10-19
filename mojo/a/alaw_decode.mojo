@export("alaw_decode")
fn alaw_decode(input: Int64) abi("C") -> Int64:
    if input < 0 or input > 255:
        return -1
    let alaw = Int32(input) ^ 0xD5
    let sign = alaw & 128
    let segment = (alaw & 112) >> 4
    var sample = ((alaw & 15) << 4) | 8
    if segment != 0:
        sample += 256
    var shift: Int32 = 0
    if segment > 1:
        shift = segment - 1
    sample <<= shift
    if sign != 0:
        return Int64(-sample)
    return Int64(sample)
