module pancake_sort

fn flip_prefix(mut values &i64, last_index usize) {
	mut first := usize(0)
	mut last := last_index
	for first < last {
		temporary := unsafe { values[first] }
		unsafe {
			values[first] = values[last]
			values[last] = temporary
		}
		first++
		last--
	}
}

// Pancake sort using prefix reversals for the shared sorting contract.
@[export: 'pancake_sort']
pub fn pancake_sort(mut values &i64, length usize) {
	mut prefix := length
	for prefix > 1 {
		mut maximum := usize(0)
		mut probe := usize(1)
		for probe < prefix {
			if unsafe { values[probe] } > unsafe { values[maximum] } {
				maximum = probe
			}
			probe++
		}
		if maximum != prefix - 1 {
			flip_prefix(mut values, maximum)
			flip_prefix(mut values, prefix - 1)
		}
		prefix--
	}
}
