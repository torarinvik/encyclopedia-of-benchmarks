package momentum

import "core:c"

MAX_LENGTH :: 64
ITERATIONS :: 100
LEARNING_RATE :: 0.01
BETA :: 0.9

@(export)
momentum :: proc "c" (input: [^]f64, length: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || length == 0 || length > MAX_LENGTH do return -1
	count := int(length)
	values: [MAX_LENGTH]f64
	velocity: [MAX_LENGTH]f64
	gradient: [MAX_LENGTH]f64
	for index := 0; index < count; index += 1 {
		value := input[index]
		if value != value || value < -1000000.0 || value > 1000000.0 do return -1
		values[index] = value
		velocity[index] = 0.0
	}
	if output == nil || int(output_capacity) < count do return -2

	for iteration := 0; iteration < ITERATIONS; iteration += 1 {
		for index := 0; index < count; index += 1 do gradient[index] = 2.0 * values[index]
		for index := 0; index < count; index += 1 {
			velocity[index] = BETA * velocity[index] + gradient[index]
			values[index] -= LEARNING_RATE * velocity[index]
		}
	}
	for index := 0; index < count; index += 1 do output[index] = values[index]
	return i64(count)
}
