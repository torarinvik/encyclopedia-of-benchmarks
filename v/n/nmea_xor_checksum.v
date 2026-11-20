module nmea_xor_checksum

@[export: 'nmea_xor_checksum']
pub fn nmea_xor_checksum(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length == 0 || length > 78 { return -1 }
		payload_length := values[0]
		if payload_length < 0 || payload_length > 76 || length != usize(payload_length + 1) {
			return -1
		}
		mut checksum := i64(0)
		for i in 1 .. int(length) {
			byte := values[i]
			if byte < 0 || byte > 127 { return -1 }
			checksum ^= byte
		}
		return checksum
	}
}
