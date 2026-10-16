package sum_multiples_inclusion_exclusion

@(export)
sum_multiples_inclusion_exclusion :: proc "contextless" (limit: i64) -> i64 {
	if limit < 1 || limit > 100_000 do return -1
	last := limit - 1
	threes := last / 3
	fives := last / 5
	fifteens := last / 15
	return 3 * threes * (threes + 1) / 2 + 5 * fives * (fives + 1) / 2 - 15 * fifteens * (fifteens + 1) / 2
}
