module entringer_number

@[export: 'entringer_number']
pub fn entringer_number(values &i64, length usize) i64 {
    if length != 2 { return -1 }
    unsafe {
        if values == nil { return -1 }
        n, target := values[0], values[1]
        if n < 0 || n > 12 || target < 0 || target > n { return -1 }
        n_int, target_int := int(n), int(target)
        mut previous := [13]i64{}
        mut current := [13]i64{}
        previous[0] = 1
        for row := 1; row <= n_int; row++ {
            current[0] = 0
            for col := 1; col <= row; col++ {
                current[col] = current[col-1] + previous[row-col]
            }
            for i in 0 .. 13 {
                previous[i] = current[i]
                current[i] = 0
            }
        }
        return previous[target_int]
    }
}
