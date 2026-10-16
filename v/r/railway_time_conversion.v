module main

const max_input_length = 10
const packed_input_length = max_input_length + 1
const output_length = 8

fn is_digit(value i64) bool {
    return value >= 48 && value <= 57
}

@[export: 'railway_time_conversion']
pub fn railway_time_conversion(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
    unsafe {
        if input == nil || length != packed_input_length || input[0] != max_input_length {
            return -1
        }

        if input[3] != 58 || input[6] != 58 ||
            !((input[9] == 65 && input[10] == 77) ||
              (input[9] == 80 && input[10] == 77)) ||
            !is_digit(input[1]) || !is_digit(input[2]) ||
            !is_digit(input[4]) || !is_digit(input[5]) ||
            !is_digit(input[7]) || !is_digit(input[8]) {
            return -1
        }

        hour := (input[1] - 48) * 10 + input[2] - 48
        minute := (input[4] - 48) * 10 + input[5] - 48
        second := (input[7] - 48) * 10 + input[8] - 48
        if hour < 1 || hour > 12 || minute > 59 || second > 59 {
            return -1
        }
        if output == nil || output_capacity < output_length {
            return -2
        }

        hour24 := hour % 12 + if input[9] == 80 { 12 } else { 0 }
        output[0] = u8(48 + hour24 / 10)
        output[1] = u8(48 + hour24 % 10)
        output[2] = 58
        output[3] = u8(input[4])
        output[4] = u8(input[5])
        output[5] = 58
        output[6] = u8(input[7])
        output[7] = u8(input[8])
        return i64(output_length)
    }
}
