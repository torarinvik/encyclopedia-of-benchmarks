module avr_speed_scaling

const max_jobs = 8
const max_time = 8
const max_segments = 15
const max_input_length = 25
const max_output_values = 79
const density_scale = i64(840)

fn gcd_i64(left i64, right i64) i64 {
	mut a := left
	mut b := right
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'avr_speed_scaling']
pub fn avr_speed_scaling(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > usize(max_input_length) { return -1 }
		count_value := input[0]
		if count_value < 1 || count_value > max_jobs { return -1 }
		count := int(count_value)
		if int(length) != 1 + 3 * count { return -1 }

		mut releases := [max_jobs]int{}
		mut deadlines := [max_jobs]int{}
		mut remaining := [max_jobs]i64{}
		mut finish_numerators := [max_jobs]i64{}
		mut finish_denominators := [max_jobs]i64{}
		mut changes := [max_time + 1]i64{}
		mut endpoint := [max_time + 1]bool{}
		for job in 0 .. count {
			offset := 1 + 3 * job
			release_value, deadline_value, work_value := input[offset], input[offset + 1], input[offset + 2]
			if release_value < 0 || release_value >= deadline_value || deadline_value > max_time ||
				work_value < 1 || work_value > 8 { return -1 }
			release, deadline, work := int(release_value), int(deadline_value), int(work_value)
			releases[job], deadlines[job] = release, deadline
			remaining[job] = i64(work) * density_scale
			scaled_density := i64(work) * (density_scale / i64(deadline - release))
			changes[release] += scaled_density
			changes[deadline] -= scaled_density
			endpoint[release], endpoint[deadline] = true, true
		}

		mut speed_scaled := i64(0)
		mut energy_scaled := i64(0)
		mut segments := [max_segments][4]i64{}
		mut segment_count := 0
		for start in 0 .. max_time {
			speed_scaled += changes[start]
			if !endpoint[start] { continue }
			mut finish := start + 1
			for finish <= max_time && !endpoint[finish] { finish++ }
			if finish > max_time || speed_scaled <= 0 { continue }

			energy_scaled += speed_scaled * speed_scaled * speed_scaled * i64(finish - start)
			speed_divisor := gcd_i64(speed_scaled, density_scale)
			speed_numerator, speed_denominator := speed_scaled / speed_divisor, density_scale / speed_divisor
			if segment_count > 0 && segments[segment_count - 1][1] == i64(start) &&
				segments[segment_count - 1][2] == speed_numerator &&
				segments[segment_count - 1][3] == speed_denominator {
				segments[segment_count - 1][1] = i64(finish)
			} else {
				segments[segment_count] = [4]i64{i64(start), i64(finish), speed_numerator, speed_denominator}
				segment_count++
			}

			mut cursor_scaled := i64(start) * speed_scaled
			end_scaled := i64(finish) * speed_scaled
			for cursor_scaled < end_scaled {
				mut selected := -1
				for job in 0 .. count {
					if releases[job] <= start && start < deadlines[job] && remaining[job] > 0 &&
						(selected < 0 || deadlines[job] < deadlines[selected]) {
						selected = job
					}
				}
				if selected < 0 { break }
				needed_scaled := remaining[selected]
				if cursor_scaled + needed_scaled <= end_scaled {
					cursor_scaled += needed_scaled
					remaining[selected] = 0
					divisor := gcd_i64(cursor_scaled, speed_scaled)
					finish_numerators[selected] = cursor_scaled / divisor
					finish_denominators[selected] = speed_scaled / divisor
				} else {
					remaining[selected] -= end_scaled - cursor_scaled
					cursor_scaled = end_scaled
				}
			}
		}

		energy_denominator := density_scale * density_scale * density_scale
		energy_divisor := gcd_i64(energy_scaled, energy_denominator)
		mut fields := [max_output_values]i64{}
		mut field_count := 0
		fields[field_count] = i64(segment_count)
		field_count++
		fields[field_count] = energy_scaled / energy_divisor
		field_count++
		fields[field_count] = energy_denominator / energy_divisor
		field_count++
		for segment in 0 .. segment_count {
			for part in 0 .. 4 {
				fields[field_count] = segments[segment][part]
				field_count++
			}
		}
		for job in 0 .. count {
			if finish_denominators[job] <= 0 { return -1 }
			fields[field_count], fields[field_count + 1] = finish_numerators[job], finish_denominators[job]
			field_count += 2
		}

		output_bytes := field_count * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for field in 0 .. field_count {
			store_i64_le(mut output, field * 8, fields[field])
		}
		return i64(output_bytes)
	}
}
