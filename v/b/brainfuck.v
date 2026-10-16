module brainfuck

// Interpret a bounded Brainfuck byte program with portable limits.
@[export: 'brainfuck']
pub fn brainfuck(values &i64, length usize, output &u8, output_capacity usize) i64 {
    unsafe {
        max_program := usize(2048)
        max_input := usize(1024)
        max_output := usize(8192)
        max_steps := usize(100000)
        tape_cells := usize(257)
        if length < 2 || length > max_program + max_input + 2 { return -2 }
        if values[0] < 0 || values[0] > 2048 { return -2 }
        program_length := usize(values[0])
        input_length_index := program_length + 1
        if input_length_index >= length || values[input_length_index] < 0
            || values[input_length_index] > 1024 { return -2 }
        input_length := usize(values[input_length_index])
        if length != program_length + input_length + 2 { return -2 }

        mut matching := [2048]i32{}
        mut openings := [2048]usize{}
        for index := usize(0); index < program_length; index++ {
            matching[index] = -1
            byte := values[index + 1]
            if byte < 32 || byte > 126 { return -2 }
        }
        mut depth := usize(0)
        for index := usize(0); index < program_length; index++ {
            byte := values[index + 1]
            if byte == 91 {
                openings[depth] = index
                depth++
            } else if byte == 93 {
                if depth == 0 { return -2 }
                depth--
                opening := openings[depth]
                matching[opening] = i32(index)
                matching[index] = i32(opening)
            }
        }
        if depth != 0 { return -2 }
        for index := usize(0); index < input_length; index++ {
            byte := values[input_length_index + 1 + index]
            if byte < 0 || byte > 255 { return -2 }
        }

        mut tape := [257]u8{}
        mut scratch := [8192]u8{}
        mut data_pointer := tape_cells / 2
        mut input_index := usize(0)
        mut instruction := usize(0)
        mut steps := usize(0)
        mut output_length := usize(0)
        for instruction < program_length {
            steps++
            if steps > max_steps { return -2 }
            command := values[instruction + 1]
            if command == 46 {
                if output_length == max_output { return -2 }
                scratch[output_length] = tape[data_pointer]
                output_length++
            } else if command == 44 {
                if input_index < input_length {
                    tape[data_pointer] = u8(values[input_length_index + 1 + input_index])
                    input_index++
                } else {
                    tape[data_pointer] = 0
                }
            } else if command == 62 {
                data_pointer++
                if data_pointer >= tape_cells { return -2 }
            } else if command == 60 {
                if data_pointer == 0 { return -2 }
                data_pointer--
            } else if command == 43 {
                tape[data_pointer]++
            } else if command == 45 {
                tape[data_pointer]--
            } else if command == 91 && tape[data_pointer] == 0 {
                instruction = usize(matching[instruction])
            } else if command == 93 && tape[data_pointer] != 0 {
                instruction = usize(matching[instruction])
            }
            instruction++
        }
        if output_length > output_capacity || (output_length != 0 && isnil(output)) { return -2 }
        for index := usize(0); index < output_length; index++ { output[index] = scratch[index] }
        return i64(output_length)
    }
}
