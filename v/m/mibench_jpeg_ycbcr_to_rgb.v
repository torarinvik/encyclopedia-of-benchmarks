module mibench_jpeg_ycbcr_to_rgb

fn arshift16(x i64) i64 { return if x >= 0 { x / 65536 } else { -((-x + 65535) / 65536) } }
fn clamp8(x i64) u8 { return u8(if x < 0 { 0 } else if x > 255 { 255 } else { x }) }

@[export: 'mibench_jpeg_ycbcr_to_rgb']
pub fn mibench_jpeg_ycbcr_to_rgb(input &i64, n usize, mut output &u8, cap usize) i64 {
  unsafe {
    if input == nil || n < 4 || n > 49 { return -1 }
    if input[0] < 1 || input[0] > 16 || n != usize(1 + 3 * input[0]) { return -1 }
    for i in 1 .. n { if input[i] < 0 || input[i] > 255 { return -1 } }
    mut staged := [48]u8{}
    mut p := 0
    for i in 0 .. (n-1)/3 {
      let idx := 1 + 3*i
      let y := input[idx]; let cb := input[idx+1]-128; let cr := input[idx+2]-128
      staged[p]=clamp8(y+arshift16(91881*cr+32768)); p++
      staged[p]=clamp8(y+arshift16(-22554*cb+32768-46802*cr)); p++
      staged[p]=clamp8(y+arshift16(116130*cb+32768)); p++
    }
    if output == nil || cap < p { return -2 }
    for i in 0 .. p { output[i]=staged[i] }
    return i64(p)
  }
}
