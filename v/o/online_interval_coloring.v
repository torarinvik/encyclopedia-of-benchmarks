// Clean-room bounded Kierstead-Trotter online interval coloring profile.
@[export: 'online_interval_coloring']
pub fn online_interval_coloring(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 129 { return -1 }
		count := input[0]
		if count < 0 || count > 64 || length != usize(1 + 2*count) { return -1 }
		n := int(count)
		mut left := []i64{len: 64, init: 0}
		mut right := []i64{len: 64, init: 0}
		for i in 0 .. n {
			left[i] = input[1+2*i]; right[i] = input[2+2*i]
			if left[i] < -1000 || left[i] > 1000 || right[i] < -1000 || right[i] > 1000 || left[i] > right[i] { return -1 }
		}
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut levels := []int{len: 64, init: 0}
		mut local := []int{len: 64, init: 0}
		mut colors := []int{len: 64, init: 0}
		for i in 0 .. n {
			mut level := 1
			for {
				mut fits := true
				for anchor in 0 .. i+1 {
					point := left[anchor]
					mut overlap := 0
					for item in 0 .. i+1 {
						if (item == i || levels[item] <= level) && left[item] <= point && point <= right[item] { overlap++ }
					}
					if overlap > level { fits = false; break }
				}
				if fits { break }
				level++
				if level > i+1 { return -1 }
			}
			levels[i] = level
			mut used := []bool{len: 3, init: false}
			for j in 0 .. i {
				if levels[j] == level && left[j] <= right[i] && left[i] <= right[j] && local[j] < 3 { used[local[j]] = true }
			}
			mut color := 0
			for color < 3 && used[color] { color++ }
			if color == 3 { return -1 }
			local[i] = color; colors[i] = 3*(level-1)+color
		}
		for i in 0 .. n {
			bits := u64(colors[i])
			for byte in 0 .. 8 { output[8*i+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
