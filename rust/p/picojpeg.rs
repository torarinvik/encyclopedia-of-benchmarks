const INPUT_BYTES: usize = 139;
const OUTPUT_BYTES: usize = 64;
const IDCT_Q16: [i64; 8] = [11363, 9633, 6436, 2260, -2260, -6436, -9633, -11363];

fn floor_q16(value: i64) -> i64 {
    if value >= 0 { value / 65536 } else { -((-value + 65535) / 65536) }
}

fn valid(v: &[i64]) -> bool {
    if [v[0],v[1],v[2],v[3],v[4],v[5],v[6]] != [255,216,255,219,0,67,0] { return false; }
    for i in 0..64 { if v[7+i] < 1 || v[7+i] > 255 || (i >= 2 && v[7+i] != 1) { return false; } }
    let sof = [255,192,0,11,8,0,8,0,8,1,1,17,0];
    if v[71..84] != sof { return false; }
    if v[84]!=255 || v[85]!=196 || v[86]!=0 || v[87]!=39 || v[88]!=0 || v[89]!=1 || v[90]!=0 || v[105]!=4
        || v[106]!=16 || v[107]!=1 || v[108]!=1 || v[123]!=4 || v[124]!=0 { return false; }
    if v[91..105].iter().any(|&x| x != 0) || v[109..123].iter().any(|&x| x != 0) { return false; }
    let sos = [255,218,0,8,1,1,0,0,63,0];
    if v[125..135] != sos { return false; }
    v[137] == 255 && v[138] == 217
}

#[no_mangle]
pub unsafe extern "C" fn picojpeg(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length != INPUT_BYTES { return -1; }
    let v = unsafe { std::slice::from_raw_parts(values, length) };
    if v.iter().any(|&x| !(0..=255).contains(&x)) || !valid(v) { return -1; }
    let scan = ((v[135] << 8) | v[136]) as u16;
    if scan & 0x8000 != 0 || scan & 0x0400 != 0 || (scan >> 4) & 3 != 2 || scan & 15 != 15 { return -1; }
    let dc_raw = ((scan >> 11) & 15) as i64;
    let ac_raw = ((scan >> 6) & 15) as i64;
    let dc = (if dc_raw >= 8 { dc_raw } else { dc_raw - 15 }) * v[7];
    let ac = (if ac_raw >= 8 { ac_raw } else { ac_raw - 15 }) * v[8];
    if output.is_null() || capacity < OUTPUT_BYTES { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, OUTPUT_BYTES) };
    for y in 0..8 { for x in 0..8 {
        let numerator = 128 * 65536 + dc * 8192 + ac * IDCT_Q16[x] + 32768;
        out[y*8+x] = floor_q16(numerator).clamp(0,255) as u8;
    }}
    OUTPUT_BYTES as i64
}
