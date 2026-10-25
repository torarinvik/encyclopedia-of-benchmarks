module cbench_lame_mid_side

const sqrt2 = 1.414213562373095048801688724209698079

@[export: 'cbench_lame_mid_side']
pub fn cbench_lame_mid_side(input &f64, n usize, mut output &f64, cap usize) i64 {
  unsafe {
    if input == nil || n == 0 || n > 66 { return -1 }
    for i in 0 .. n { if !input[i].is_finite() { return -1 } }
    if input[0] < 1.0 || input[0] > 32.0 || input[0] != f64(int(input[0])) { return -1 }
    count := int(input[0])
    if n != usize(1+2*count) { return -1 }
    for i in 1 .. n { if input[i] < -16.0 || input[i] > 16.0 { return -1 } }
    mut staged := [64]f64{}
    factor := sqrt2*0.5
    for i in 0 .. count {
      left := input[1+i]; right := input[1+count+i]
      staged[2*i]=(left+right)*factor
      staged[2*i+1]=(left-right)*factor
    }
    needed := 2*count
    if output == nil || cap < usize(needed) { return -2 }
    for i in 0 .. needed { output[i]=staged[i] }
    return i64(needed)
  }
}
