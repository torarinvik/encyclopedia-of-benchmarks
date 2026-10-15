#[no_mangle]
pub extern "C" fn alaw_decode(input: i64) -> i64 {
    if !(0..=255).contains(&input) {
        return -1;
    }
    let alaw = (input as i32) ^ 0xD5;
    let sign = alaw & 0x80;
    let segment = (alaw & 0x70) >> 4;
    let mut sample = ((alaw & 0x0F) << 4) | 8;
    if segment != 0 {
        sample += 0x100;
    }
    let shift = if segment > 1 { segment - 1 } else { 0 };
    sample <<= shift;
    if sign != 0 { i64::from(-sample) } else { i64::from(sample) }
}
