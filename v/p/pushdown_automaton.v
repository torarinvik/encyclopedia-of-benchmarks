module pushdown_automaton

// Recognize the bounded language (1|2)^n 0^n with a pushdown-style counter.
@[export: 'pushdown_automaton']
pub fn pushdown_automaton(values &i64, length usize) i64 {
	if length < 1 || unsafe { values == nil } { return -1 }
	unsafe {
		if length > 257 || values[0] < 0 || values[0] > 256 { return -1 }
		count := int(values[0])
		if int(length) != count + 1 { return -1 }
		for index in 0 .. count {
			if values[index + 1] < 48 || values[index + 1] > 50 { return -1 }
		}
		if count == 0 || count % 2 != 0 { return 0 }
		half := count / 2
		for index in 0 .. half {
			if values[index + 1] != 49 && values[index + 1] != 50 { return 0 }
		}
		for index in half .. count {
			if values[index + 1] != 48 { return 0 }
		}
		return 1
	}
}
