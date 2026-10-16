module cusum_detector

fn put_i64_le(mut output &u8, offset int, value i64) {
    mut bits := u64(value)
    for b in 0 .. 8 {
        unsafe { output[offset+b] = u8(bits & 255) }
        bits >>= 8
    }
}
@[export: 'cusum_detector']
pub fn cusum_detector(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 5 { return -1 }
    unsafe {
        n64:=input[0]
        if n64<0 || n64>128 || length!=usize(n64)+5 { return -1 }
        n:=int(n64)
        target,sigma,allowance,threshold:=input[1],input[2],input[3],input[4]
        if target < -1000 || target > 1000 || sigma < 1 || sigma > 1000 || allowance < 0 || allowance > 1000 || threshold < 1 || threshold > 1000 { return -1 }
        for i in 0 .. n { if input[5+i] < -1000 || input[5+i] > 1000 { return -1 } }
        if capacity<n*8 || (n>0 && output==nil) { return -2 }
        mut upper:=f64(0); mut lower:=f64(0)
        for i in 0 .. n {
            z:=(f64(input[5+i])-f64(target))/f64(sigma)
            upper+=z-f64(allowance); if upper<0 { upper=0 }
            lower+=-z-f64(allowance); if lower<0 { lower=0 }
            mut signal:=i64(0)
            if upper>f64(threshold) { signal=1 } else if lower>f64(threshold) { signal=-1 }
            if signal!=0 { upper=0; lower=0 }
            put_i64_le(mut output,i*8,signal)
        }
        return i64(n*8)
    }
}
