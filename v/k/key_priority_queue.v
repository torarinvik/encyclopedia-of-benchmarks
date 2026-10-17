module key_priority_queue

@[export: 'key_priority_queue']
pub fn key_priority_queue(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 98 { return -1 }
	if unsafe { input[0] < 0 || input[0] > 32 } { return -1 }
	mut keys := []i64{len: 32}
	mut priorities := []i64{len: 32}
	mut answers := []i64{len: 32}
	mut n := 0
	mut out_n := 0
	mut pos := 1
	for _ in 0 .. int(unsafe { input[0] }) {
		if pos >= length { return -1 }
		op := unsafe { input[pos] }
		if op == 0 || op == 1 {
			if pos + 2 >= length { return -1 }
			key := unsafe { input[pos + 1] }; priority := unsafe { input[pos + 2] }
			if key < -1000000000 || key > 1000000000 || priority < -1000000000 || priority > 1000000000 { return -1 }
			pos += 3
			mut found := n
			for i in 0 .. n { if keys[i] == key { found = i; break } }
			if op == 0 {
				if found != n { return -1 }
				keys[n] = key; priorities[n] = priority
				mut i := n
				for i > 0 { parent := (i - 1) / 2; if priorities[parent] <= priorities[i] { break }; keys[parent], keys[i] = keys[i], keys[parent]; priorities[parent], priorities[i] = priorities[i], priorities[parent]; i = parent }
				n++
			} else if found == n {
				keys[n] = key; priorities[n] = priority
				mut i := n
				for i > 0 { parent := (i - 1) / 2; if priorities[parent] <= priorities[i] { break }; keys[parent], keys[i] = keys[i], keys[parent]; priorities[parent], priorities[i] = priorities[i], priorities[parent]; i = parent }
				n++
			} else {
				priorities[found] = priority
				if found > 0 && priorities[(found - 1) / 2] > priority {
					mut i := found
					for i > 0 { parent := (i - 1) / 2; if priorities[parent] <= priorities[i] { break }; keys[parent], keys[i] = keys[i], keys[parent]; priorities[parent], priorities[i] = priorities[i], priorities[parent]; i = parent }
				} else {
					left := 2 * found + 1; right := left + 1
					if (left < n && priorities[left] < priority) || (right < n && priorities[right] < priority) {
						mut i := found
						for 2 * i + 1 < n { l := 2 * i + 1; r := l + 1; mut child := n
							if priorities[l] < priorities[i] && (r >= n || priorities[l] < priorities[r]) { child = l }
							else if r < n && priorities[r] < priorities[i] { child = r } else { break }
							keys[i], keys[child] = keys[child], keys[i]; priorities[i], priorities[child] = priorities[child], priorities[i]; i = child
						}
					}
				}
			}
		} else if op == 2 {
			pos++
			if n == 0 { return -1 }
			keys[0], keys[n - 1] = keys[n - 1], keys[0]; priorities[0], priorities[n - 1] = priorities[n - 1], priorities[0]
			n--; answers[out_n] = keys[n]; out_n++
			if n > 0 {
				mut i := 0
				for 2 * i + 1 < n { l := 2 * i + 1; r := l + 1; mut child := n
					if priorities[l] < priorities[i] && (r >= n || priorities[l] < priorities[r]) { child = l }
					else if r < n && priorities[r] < priorities[i] { child = r } else { break }
					keys[i], keys[child] = keys[child], keys[i]; priorities[i], priorities[child] = priorities[child], priorities[i]; i = child
				}
			}
		} else if op == 3 {
			if pos + 1 >= length { return -1 }
			key := unsafe { input[pos + 1] }
			if key < -1000000000 || key > 1000000000 { return -1 }
			pos += 2; mut present := false
			for i in 0 .. n { if keys[i] == key { present = true; break } }
			answers[out_n] = if present { 1 } else { 0 }; out_n++
		} else if op == 4 { pos++; answers[out_n] = if n == 0 { 1 } else { 0 }; out_n++ }
		else { return -1 }
	}
	if pos != length { return -1 }
	bytes := out_n * 8
	if unsafe { output == nil } || output_capacity < bytes { return -2 }
	for i in 0 .. out_n { bits := u64(answers[i]); for b in 0 .. 8 { unsafe { output[8 * i + b] = u8(bits >> (8 * b)) } } }
	return i64(bytes)
}
