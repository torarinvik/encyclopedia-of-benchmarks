package avr_speed_scaling

import "core:c"

MAX_JOBS :: 8
MAX_TIME :: 8
MAX_SEGMENTS :: 15
MAX_INPUT_LENGTH :: 25
MAX_OUTPUT_VALUES :: 79
DENSITY_SCALE :: i64(840)

gcd_i64 :: proc(left, right: i64) -> i64 {
	a, b := left, right
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
avr_speed_scaling :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
	count_value := input[0]
	if count_value < 1 || count_value > MAX_JOBS do return -1
	count := int(count_value)
	if int(length) != 1 + 3 * count do return -1

	var releases: [MAX_JOBS]int
	var deadlines: [MAX_JOBS]int
	var remaining: [MAX_JOBS]i64
	var finish_numerators: [MAX_JOBS]i64
	var finish_denominators: [MAX_JOBS]i64
	var changes: [MAX_TIME + 1]i64
	var endpoint: [MAX_TIME + 1]bool
	for job := 0; job < count; job += 1 {
		offset := 1 + 3 * job
		release_value, deadline_value, work_value := input[offset], input[offset+1], input[offset+2]
		if release_value < 0 || release_value >= deadline_value || deadline_value > MAX_TIME ||
			work_value < 1 || work_value > 8 do return -1
		release, deadline, work := int(release_value), int(deadline_value), int(work_value)
		releases[job], deadlines[job] = release, deadline
		remaining[job] = i64(work) * DENSITY_SCALE
		scaled_density := i64(work) * (DENSITY_SCALE / i64(deadline-release))
		changes[release] += scaled_density
		changes[deadline] -= scaled_density
		endpoint[release], endpoint[deadline] = true, true
	}

	speed_scaled, energy_scaled := i64(0), i64(0)
	var segments: [MAX_SEGMENTS][4]i64
	segment_count := 0
	for start := 0; start < MAX_TIME; start += 1 {
		speed_scaled += changes[start]
		if !endpoint[start] do continue
		finish := start + 1
		for finish <= MAX_TIME && !endpoint[finish] { finish += 1 }
		if finish > MAX_TIME || speed_scaled <= 0 do continue

		duration := i64(finish - start)
		energy_scaled += speed_scaled * speed_scaled * speed_scaled * duration
		speed_divisor := gcd_i64(speed_scaled, DENSITY_SCALE)
		speed_numerator, speed_denominator := speed_scaled / speed_divisor, DENSITY_SCALE / speed_divisor
		if segment_count > 0 && segments[segment_count-1][1] == i64(start) &&
			segments[segment_count-1][2] == speed_numerator &&
			segments[segment_count-1][3] == speed_denominator {
			segments[segment_count-1][1] = i64(finish)
		} else {
			segments[segment_count] = [4]i64{i64(start), i64(finish), speed_numerator, speed_denominator}
			segment_count += 1
		}

		cursor_scaled := i64(start) * speed_scaled
		end_scaled := i64(finish) * speed_scaled
		for cursor_scaled < end_scaled {
			selected := -1
			for job := 0; job < count; job += 1 {
				if releases[job] <= start && start < deadlines[job] && remaining[job] > 0 &&
					(selected < 0 || deadlines[job] < deadlines[selected]) {
					selected = job
				}
			}
			if selected < 0 do break
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

	energy_denominator := DENSITY_SCALE * DENSITY_SCALE * DENSITY_SCALE
	energy_divisor := gcd_i64(energy_scaled, energy_denominator)
	var fields: [MAX_OUTPUT_VALUES]i64
	field_count := 0
	fields[field_count] = i64(segment_count)
	field_count += 1
	fields[field_count] = energy_scaled / energy_divisor
	field_count += 1
	fields[field_count] = energy_denominator / energy_divisor
	field_count += 1
	for segment := 0; segment < segment_count; segment += 1 {
		for part := 0; part < 4; part += 1 {
			fields[field_count] = segments[segment][part]
			field_count += 1
		}
	}
	for job := 0; job < count; job += 1 {
		if finish_denominators[job] <= 0 do return -1
		fields[field_count], fields[field_count+1] = finish_numerators[job], finish_denominators[job]
		field_count += 2
	}

	output_bytes := field_count * 8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for field := 0; field < field_count; field += 1 do store_i64_le(output, field*8, fields[field])
	return i64(output_bytes)
}
