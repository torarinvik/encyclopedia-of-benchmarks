module straddling_checkerboard_transducer

const max_input = 97
const max_text = 64
const board_size = 30
const max_output = 128

fn parse_board(input &i64, length usize, mut hole_a int, mut hole_b int,
    mut text_length int, mut mode i64) bool {
    if input == nil || length < 32 || length > max_input { return false }
    mode = unsafe { input[0] }
    if mode != 0 && mode != 1 { return false }
    mut holes := 0
    for position in 0 .. board_size {
        value := unsafe { input[1 + position] }
        if position < 10 && value == 0 {
            if holes == 0 { hole_a = position } else if holes == 1 { hole_b = position }
            holes++
            continue
        }
        if value < 32 || value > 126 { return false }
        for prior in 0 .. position {
            if unsafe { input[1 + prior] } == value { return false }
        }
    }
    if holes != 2 { return false }
    count := unsafe { input[31] }
    if count < 0 || count > max_text { return false }
    text_length = int(count)
    return length == 32 + text_length
}

fn find_symbol(input &i64, value i64) int {
    for position in 0 .. board_size {
        if unsafe { input[1 + position] } != 0 && unsafe { input[1 + position] } == value { return position }
    }
    return -1
}

fn measure_decode(input &i64, text_length int, hole_a int, hole_b int,
    mut result_length int) bool {
    mut index := 0
    for index < text_length {
        value := unsafe { input[32 + index] }
        if value < `0` || value > `9` { return false }
        column := int(value - `0`)
        if unsafe { input[1 + column] } != 0 {
            result_length++
            index++
            continue
        }
        if (column != hole_a && column != hole_b) || index + 1 >= text_length { return false }
        next := unsafe { input[32 + index + 1] }
        if next < `0` || next > `9` { return false }
        result_length++
        index += 2
    }
    return true
}

@[export: 'straddling_checkerboard_transducer']
pub fn straddling_checkerboard_transducer(input &i64, length usize,
    output &u8, output_capacity usize) i64 {
    mut hole_a := -1
    mut hole_b := -1
    mut text_length := 0
    mut mode := i64(-1)
    if !parse_board(input, length, mut hole_a, mut hole_b, mut text_length, mut mode) { return -1 }

    mut result_length := 0
    if mode == 0 {
        for index in 0 .. text_length {
            position := find_symbol(input, unsafe { input[32 + index] })
            if position < 0 { return -1 }
            result_length += if position < 10 { 1 } else { 2 }
        }
    } else if !measure_decode(input, text_length, hole_a, hole_b, mut result_length) {
        return -1
    }
    if result_length > max_output { return -1 }
    if output == nil || output_capacity < result_length { return -2 }

    if mode == 0 {
        mut out := 0
        for index in 0 .. text_length {
            position := find_symbol(input, unsafe { input[32 + index] })
            if position < 10 {
                unsafe { output[out] = u8(`0` + position) }
                out++
            } else {
                row_digit := if position < 20 { hole_a } else { hole_b }
                unsafe {
                    output[out] = u8(`0` + row_digit)
                    output[out + 1] = u8(`0` + position % 10)
                }
                out += 2
            }
        }
    } else {
        mut index := 0
        mut out := 0
        for index < text_length {
            column := int(unsafe { input[32 + index] } - `0`)
            if unsafe { input[1 + column] } != 0 {
                unsafe { output[out] = u8(input[1 + column]) }
                index++
            } else {
                row := if column == hole_a { 1 } else { 2 }
                next_column := int(unsafe { input[32 + index + 1] } - `0`)
                unsafe { output[out] = u8(input[1 + row * 10 + next_column]) }
                index += 2
            }
            out++
        }
    }
    return i64(result_length)
}
