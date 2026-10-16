module rgbhex

@[export: 'rgbhex']
pub fn rgbhex(input &i64, length usize) i64 {
    if unsafe { input == nil } || length != 4 { return -1 }
    op := unsafe { input[0] }
    x := unsafe { input[1] }
    y := unsafe { input[2] }
    z := unsafe { input[3] }
    if op == 0 {
        if x < 0 || x > 4294967295 || y != 0 || z != 0 { return -1 }
        return x & 0x00ffffff
    }
    if op == 1 {
        if x < 0 || x > 255 || y < 0 || y > 255 || z < 0 || z > 255 { return -1 }
        return (x << 16) | (y << 8) | z
    }
    return -1
}
