module hofstadter_conway_10000_sequence

const max_index = i64(8192)
const max_parseable_length = usize(2)

@[export: 'hofstadter_conway_10000_sequence']
pub fn hofstadter_conway_10000_sequence(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_parseable_length { return -1 }
	unsafe {
		if length != 1 || input[0] < 2 || input[0] > max_index { return -1 }
		target := int(input[0])
		mut a := [8193]i64{}
		a[1] = 1
		a[2] = 1
		for n := 3; n <= target; n++ {
			previous := a[n - 1]
			other := i64(n) - previous
			if previous < 1 || previous >= i64(n) || other < 1 || other >= i64(n) { return -1 }
			a[n] = a[int(previous)] + a[int(other)]
		}
		return a[target]
	}
}
