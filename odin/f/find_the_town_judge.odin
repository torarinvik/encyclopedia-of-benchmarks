package find_the_town_judge

import "core:c"

MAX_PEOPLE :: 1000
MAX_TRUST_ROWS :: 10000

@(export)
find_the_town_judge :: proc "contextless" (values: [^]i64, length: c.size_t) -> i64 {
	if length < 2 || length > 20002 || values == nil do return -2
	people := values[0]
	trust_count := values[1]
	if people < 1 || people > MAX_PEOPLE || trust_count < 0 || trust_count > MAX_TRUST_ROWS do return -2
	edge_count := c.size_t(trust_count)
	if length != 2 + 2 * edge_count do return -2

	mut incoming: [MAX_PEOPLE + 1]i64
	mut outgoing: [MAX_PEOPLE + 1]i64
	for person := c.size_t(0); person <= MAX_PEOPLE; person += 1 {
		incoming[person] = 0
		outgoing[person] = 0
	}
	for edge := c.size_t(0); edge < edge_count; edge += 1 {
		from := values[2 + 2 * edge]
		to := values[3 + 2 * edge]
		if from < 1 || from > people || to < 1 || to > people || from == to do return -2
		outgoing[c.size_t(from)] += 1
		incoming[c.size_t(to)] += 1
	}
	mut judge := i64(-1)
	for person := i64(1); person <= people; person += 1 {
		if incoming[c.size_t(person)] == people - 1 && outgoing[c.size_t(person)] == 0 {
			if judge != -1 do return -1
			judge = person
		}
	}
	return judge
}
