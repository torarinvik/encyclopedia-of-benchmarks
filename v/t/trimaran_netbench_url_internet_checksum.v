// Modified source-related port of NetBench url.c; see bundled LICENSE_NOTICE.txt.
module trimaran_netbench_url_internet_checksum

@[export: 'trimaran_netbench_url_internet_checksum']
pub fn trimaran_netbench_url_internet_checksum(values &i64, length usize) i64 {
	if values == nil || length < 2 || length > 66 { return -1 }
	unsafe {
		mode := values[0]
		count_value := values[1]
		if (mode != 0 && mode != 1) || count_value < 0 || count_value > 64 || length != usize(count_value) + 2 { return -1 }
		count := int(count_value)
		for i in 0 .. count { if values[i + 2] < 0 || values[i + 2] > 255 { return -1 } }
		mut sum := u64(0)
		mut i := 0
		for i + 1 < count {
			word := u64(values[i + 2]) | (u64(values[i + 3]) << 8)
			sum -= word + 1
			i += 2
		}
		if i < count { sum += u64(values[i + 2]) }
		for sum >> 16 != 0 { sum = (sum & 0xffff) + (sum >> 16) }
		if mode == 1 { sum = ((sum >> 8) | ((sum << 8) & 0xff00)) & 0xffff }
		return i64(sum)
	}
}
