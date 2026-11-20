package paint_house_iii

import "core:c"

MAX_INPUT :: 44
INF :: i64(801)

state_index :: proc(color, groups: int) -> int { return color * 9 + groups }

@(export)
paint_house_iii :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	m_value, n_value, target_value := input[0], input[1], input[2]
	if m_value < 1 || m_value > 8 || n_value < 1 || n_value > 4 do return -1
	if target_value < 1 || target_value > m_value do return -1
	m, n, target := int(m_value), int(n_value), int(target_value)
	if length != c.size_t(3 + m + m*n) do return -1
	houses_at, costs_at := 3, 3 + m
	for index := 0; index < m; index += 1 {
		if input[houses_at+index] < 0 || input[houses_at+index] > n_value do return -1
	}
	for index := 0; index < m*n; index += 1 {
		if input[costs_at+index] < 0 || input[costs_at+index] > 100 do return -1
	}

	previous, current: [45]i64
	for index := 0; index < 45; index += 1 do previous[index] = INF
	first := input[houses_at]
	for color := 1; color <= n; color += 1 {
		if first == 0 || first == i64(color) {
			previous[state_index(color, 1)] = if first == 0 then input[costs_at+color-1] else 0
		}
	}
	for house := 1; house < m; house += 1 {
		for index := 0; index < 45; index += 1 do current[index] = INF
		fixed := input[houses_at+house]
		for color := 1; color <= n; color += 1 {
			if fixed != 0 && fixed != i64(color) do continue
			paint_cost := i64(0)
			if fixed == 0 do paint_cost = input[costs_at+house*n+color-1]
			for groups := 1; groups <= target; groups += 1 {
				best := INF
				for old_color := 1; old_color <= n; old_color += 1 {
					decrement := 0
					if old_color != color do decrement = 1
					old_groups := groups - decrement
					if old_groups >= 1 && previous[state_index(old_color, old_groups)] < best {
						best = previous[state_index(old_color, old_groups)]
					}
				}
				if best < INF do current[state_index(color, groups)] = best + paint_cost
			}
		}
		for index := 0; index < 45; index += 1 do previous[index] = current[index]
	}
	answer := INF
	for color := 1; color <= n; color += 1 {
		if previous[state_index(color, target)] < answer do answer = previous[state_index(color, target)]
	}
	if answer >= INF do return -1
	return answer
}
