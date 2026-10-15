#[no_mangle]
pub extern "C" fn alaw_encode(input: i64) -> i64 {
    if !(-32768..=32767).contains(&input) {
        return -1;
    }
    let sample = input as i32;
    let sign = if sample < 0 { 0x80 } else { 0 };
    let magnitude = if sample < 0 { -sample - 1 } else { sample };
    let mut segment = 7;
    let mut mask = 0x4000;
    while (magnitude & mask) == 0 && segment > 0 {
        segment -= 1;
        mask >>= 1;
    }
    let shift = if segment != 0 { segment + 3 } else { 4 };
    let quantization = (magnitude >> shift) & 0x0f;
    i64::from((sign | (segment << 4) | quantization) ^ 0xD5)
}
