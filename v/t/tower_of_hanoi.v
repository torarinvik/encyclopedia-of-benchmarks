module tower_of_hanoi

fn emit_hanoi(disks usize, source u8, destination u8, auxiliary u8,
        output &u8, position usize) usize {
    if disks == 0 { return position }
    after_first := emit_hanoi(disks - 1, source, auxiliary, destination, output, position)
    unsafe {
        output[after_first] = source
        output[after_first + 1] = destination
    }
    return emit_hanoi(disks - 1, auxiliary, destination, source, output, after_first + 2)
}

@[export: 'tower_of_hanoi']
pub fn tower_of_hanoi(values &i64, length usize, output &u8, output_capacity usize) i64 {
    if length != 4 { return -1 }
    unsafe {
        if values[0] < 0 || values[0] > 12 { return -1 }
        for index := usize(1); index < 4; index++ {
            if values[index] < 0 || values[index] > 2 { return -1 }
        }
        if values[1] == values[2] || values[1] == values[3] || values[2] == values[3] { return -1 }
        disks := usize(values[0])
        move_count := (usize(1) << disks) - 1
        required := move_count * 2
        if output_capacity < required { return -2 }
        _ = emit_hanoi(disks, u8(values[1]), u8(values[2]), u8(values[3]), output, 0)
        return i64(move_count)
    }
}
