module consistent_overhead_byte_stuffing

const max_words = usize(257)
const max_payload = i64(255)
const max_output = 257

@[export: 'consistent_overhead_byte_stuffing']
pub fn consistent_overhead_byte_stuffing(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_words { return -1 }
		payload_value := input[0]
		if payload_value < 0 || payload_value > max_payload { return -1 }
		payload_length := int(payload_value)
		if length != usize(payload_length + 1) { return -1 }
		for index in 0 .. payload_length {
			if input[index + 1] < 0 || input[index + 1] > 255 { return -1 }
		}

		mut staged := [max_output]u8{}
		mut written := 1
		mut code_position := 0
		mut code := u16(1)
		mut omitted_terminal_code := false
		for index in 0 .. payload_length {
			byte := u8(input[index + 1])
			if byte == 0 {
				staged[code_position] = u8(code)
				code_position = written
				written++
				code = 1
			} else {
				staged[written] = byte
				written++
				code++
				if code == 255 {
					staged[code_position] = 255
					if index + 1 == payload_length {
						omitted_terminal_code = true
						break
					}
					code_position = written
					written++
					code = 1
				}
			}
		}
		if !omitted_terminal_code { staged[code_position] = u8(code) }
		if output == nil || capacity < usize(written) { return -2 }
		for index in 0 .. written { output[index] = staged[index] }
		return i64(written)
	}
}
