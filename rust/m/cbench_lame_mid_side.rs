const MAX_SAMPLES: usize = 32;
const MAX_INPUT: usize = 65;
const MAX_OUTPUT: usize = 64;
const SQRT2: f64 = 1.414213562373095048801688724209698079;

#[no_mangle]
pub unsafe extern "C" fn cbench_lame_mid_side(input: *const f64, n: usize, output: *mut f64, cap: usize) -> i64 {
    if input.is_null() || n == 0 || n > MAX_INPUT + 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, n) };
    if values.iter().any(|x| !x.is_finite()) { return -1; }
    if values[0] < 1.0 || values[0] > MAX_SAMPLES as f64 || values[0].trunc() != values[0] { return -1; }
    let count = values[0] as usize;
    if n != 1 + 2*count { return -1; }
    if values[1..].iter().any(|x| *x < -16.0 || *x > 16.0) { return -1; }
    let mut staged=[0.0_f64; MAX_OUTPUT];
    let factor=SQRT2 * 0.5;
    for i in 0..count {
        let left=values[1+i]; let right=values[1+count+i];
        staged[2*i]=(left+right)*factor;
        staged[2*i+1]=(left-right)*factor;
    }
    let needed=2*count;
    if output.is_null() || cap<needed { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, needed); }
    needed as i64
}
