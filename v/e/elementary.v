module elementary
@[export: 'elementary']
pub fn elementary(v &i64, n usize, out &u8, capacity usize) i64 {
    if unsafe { v == nil } || n < 2 || n > 129 { return -1 }
    count := unsafe { v[0] }
    if count < 1 || count > 128 || n != int(count)+1 || unsafe { v[1] } != 0 { return -1 }
    for i in 1..n { value := unsafe { v[i] }; if value != 0 && value != 1 { return -1 } }
    if capacity < int(count) || unsafe { out == nil } { return -2 }
    for i in 0..int(count) {
        l := i64(0); if i > 0 { l = unsafe { v[i] } }
        c := unsafe { v[i+1] }; r := i64(0); if i+1 < int(count) { r = unsafe { v[i+2] } }
        unsafe { out[i] = u8((30 >> (l*4+c*2+r)) & 1) }
    }
    return count
}
