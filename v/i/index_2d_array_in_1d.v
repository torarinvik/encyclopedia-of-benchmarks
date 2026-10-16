module index_2d_array_in_1d

@[export: 'index_2d_array_in_1d']
pub fn index_2d_array_in_1d(input &i64, length usize) i64 {
    if unsafe { input == nil } || length < 4 { return -1 }
    unsafe {
        rows, cols, index := input[0], input[1], input[2]
        if rows < 1 || rows > 32 || cols < 1 || cols > 32 { return -1 }
        cells := rows*cols
        if length != usize(cells)+3 || index < 0 || index >= cells { return -1 }
        for i in 0 .. int(cells) { if input[3+i] < 0 || input[3+i] > 1000000 { return -1 } }
        row, col := int(index/cols), int(index%cols)
        return input[3+row*int(cols)+col]
    }
}
