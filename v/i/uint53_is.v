module uint53_is

const uint53_limit = i64(9007199254740992)

@[export: 'uint53_is']
pub fn uint53_is(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 1 {
		return -1
	}
	value := unsafe { input[0] }
	return if value >= 0 && value < uint53_limit { 1 } else { 0 }
}
