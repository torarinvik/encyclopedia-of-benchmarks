module fast_walsh_hadamard_transform

@[export: 'fast_walsh_hadamard_transform']
pub fn fast_walsh_hadamard_transform(values &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if values == nil || length < 2 || length > 130 || (values[0] != 0 && values[0] != 1) || values[1] < 1 || values[1] > 128 { return -1 }
        n := int(values[1]); if (n & (n - 1)) != 0 || length != usize(n + 2) { return -1 }
        mut a := []i64{len: 128, init: 0}
        for i in 0 .. n { if values[i+2] < -10000 || values[i+2] > 10000 { return -1 }; a[i] = values[i+2] }
        mut h := 1
        for h < n {
            mut b := 0
            for b < n {
                for j in 0 .. h { x := a[b+j]; y := a[b+j+h]; a[b+j] = x+y; a[b+j+h] = x-y }
                b += 2*h
            }
            h *= 2
        }
        if values[0] == 1 { for i in 0 .. n { if a[i] % i64(n) != 0 { return -1 }; a[i] /= i64(n) } }
        if n*8 > int(capacity) || output == nil { return -2 }
        for i in 0 .. n { x := u64(a[i]); for k in 0 .. 8 { output[i*8+k] = u8((x >> u64(k*8)) & 255) } }
        return i64(n)
    }
}
