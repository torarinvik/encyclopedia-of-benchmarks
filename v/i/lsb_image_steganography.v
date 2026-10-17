@[export: 'lsb_image_steganography']
pub fn lsb_image_steganography(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
    if length < 3 || length > 292 || unsafe { input == nil } { return -1 }
    unsafe {
        if input[0] < 1 || input[0] > 16 || input[1] < 1 || input[1] > 16 || input[2] < 0 || input[2] > 32 { return -1 }
        rows := int(input[0]); columns := int(input[1]); message_length := int(input[2])
        pixel_count := rows * columns
        if message_length * 8 > pixel_count || int(length) != 3 + pixel_count + message_length { return -1 }
        for i in 0 .. pixel_count {
            if input[3 + i] < 0 || input[3 + i] > 254 { return -1 }
        }
        for i in 0 .. message_length {
            if input[3 + pixel_count + i] < 0 || input[3 + pixel_count + i] > 127 { return -1 }
        }
        if output == nil || output_capacity < usize(pixel_count) { return -2 }
        for i in 0 .. pixel_count { output[i] = u8(input[3 + i]) }
        mut bit_index := 0
        for i in 0 .. message_length {
            byte := u8(input[3 + pixel_count + i])
            for shift := 7; shift >= 0; shift-- {
                bit := (byte >> u32(shift)) & u8(1)
                pixel := output[bit_index]
                output[bit_index] = pixel + ((pixel & u8(1)) ^ bit)
                bit_index++
            }
        }
        return i64(pixel_count)
    }
}
