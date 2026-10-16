@[export: 'erosion_operation']
pub fn erosion_operation(input &i64, length usize) i64 {
    if isnil(input) || length < 2 || length > 38 { return -1 }
    height, width := unsafe { input[0] }, unsafe { input[1] }
    if height < 1 || height > 6 || width < 1 || width > 6 || length != usize(2 + height * width) { return -1 }
    for i in usize(2)..length { if unsafe { input[i] } != 0 && unsafe { input[i] } != 1 { return -1 } }
    if height < 3 || width < 3 { return 0 }
    mut result := i64(0)
    for row in i64(1)..height-1 {
        for col in i64(1)..width-1 {
            at := usize(2 + row * width + col)
            unsafe {
                if input[at] == 1 && input[at-width] == 1 && input[at+width] == 1 && input[at-1] == 1 && input[at+1] == 1 {
                    result |= i64(1) << (row * width + col)
                }
            }
        }
    }
    return result
}
