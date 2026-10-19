module misc_lowercase

const max_characters = 31
const max_output_bytes = 63

@[export: 'misc_lowercase']
pub fn misc_lowercase(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || input_length < 1 || input_length > max_characters + 2 {
			return -1
		}
		raw_length := input[0]
		if raw_length < 0 || raw_length > max_characters || input_length != usize(raw_length + 1) {
			return -1
		}
		length := int(raw_length)
		mut lowered := [max_characters]u16{}
		mut ascii_flag := u8(1)
		for index in 0 .. length {
			raw := input[index + 1]
			if raw < 0 || raw > 65535 {
				return -1
			}
			mut value := u16(raw)
			if value > 0x7f { ascii_flag = 0 }
			if value >= u16(`A`) && value <= u16(`Z`) { value += 32 }
			lowered[index] = value
		}
		required := 1 + 2 * length
		if isnil(output) || output_capacity < required {
			return -2
		}
		mut staged := [max_output_bytes]u8{}
		staged[0] = ascii_flag
		for index in 0 .. length {
			staged[1 + 2 * index] = u8(lowered[index] & 0xff)
			staged[2 + 2 * index] = u8(lowered[index] >> 8)
		}
		for index in 0 .. required { output[index] = staged[index] }
		return i64(required)
	}
}
