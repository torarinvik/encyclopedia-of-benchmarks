module juggler_sequence

fn floor_sqrt(value i64) i64 {
	mut low := i64(0)
	mut high := value + 1
	for high - low > 1 {
		middle := low + (high - low) / 2
		if middle <= value / middle { low = middle } else { high = middle }
	}
	return low
}

// Encode the Juggler sequence through its first 1 as little-endian u32 values.
@[export: 'juggler_sequence']
pub fn juggler_sequence(value i64, mut output &u8, output_capacity usize) i64 {
	if value < 1 || value > 25 { return -1 }
	mut sequence := [16]i64{}
	mut count := 1
	sequence[0] = value
	for sequence[count - 1] != 1 {
		current := sequence[count - 1]
		if current % 2 == 0 { sequence[count] = floor_sqrt(current) }
		else { sequence[count] = floor_sqrt(current * current * current) }
		count++
	}
	required := count * 4
	if output_capacity < usize(required) { return -2 }
	for index in 0 .. count {
		term := u32(sequence[index])
		for byte in 0 .. 4 {
			unsafe { output[4 * index + byte] = u8((term >> (8 * byte)) & 255) }
		}
	}
	return i64(required)
}
