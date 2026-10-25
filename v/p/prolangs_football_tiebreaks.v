module prolangs_football_tiebreaks

struct Fraction {
	numerator   i64
	denominator i64
}

struct Group {
	lo int
	hi int
	stage int
}

fn same_division(v &i64, order []int, lo int, hi int) bool {
	first := 1 + 12 * order[lo]
	for p := lo + 1; p < hi; p++ {
		current := 1 + 12 * order[p]
		if unsafe { v[first + 1] } != unsafe { v[current + 1] } || unsafe { v[first + 2] } != unsafe { v[current + 2] } { return false }
	}
	return true
}

fn score_for(v &i64, n int, order []int, lo int, hi int, team int, stage int, same_div bool) Fraction {
	if stage == 0 {
		cells := n * n
		wins_start := 1 + 12 * n
		ties_start := wins_start + cells
		mut won := i64(0)
		mut lost := i64(0)
		mut tied := i64(0)
		for p := lo; p < hi; p++ {
			other := order[p]
			if other == team { continue }
			won += unsafe { v[wins_start + team * n + other] }
			lost += unsafe { v[wins_start + other * n + team] }
			tied += unsafe { v[ties_start + team * n + other] }
		}
		games := won + lost + tied
		denom := i64(2) * games
		if games == 0 { denom = 1 }
		return Fraction{numerator: 2 * won + tied, denominator: denom}
	}
	base := 1 + 12 * team
	if stage >= 1 && stage <= 3 {
		field := 7
		if stage == 1 { field = 3 } else if stage == 2 { field = 5 }
		points := unsafe { v[base + field] }
		games := unsafe { v[base + field + 1] }
		denom := i64(2) * games
		if games == 0 { denom = 1 }
		return Fraction{numerator: points, denominator: denom}
	}
	if stage == 4 {
		field := 10
		if same_div { field = 9 }
		return Fraction{numerator: unsafe { v[base + field] }, denominator: 1}
	}
	return Fraction{numerator: unsafe { v[base + 11] }, denominator: 1}
}

fn compare_score(a Fraction, b Fraction) int {
	left := a.numerator * b.denominator
	right := b.numerator * a.denominator
	if left > right { return 1 }
	if left < right { return -1 }
	return 0
}

fn refine(v &i64, n int, mut order []int, lo int, hi int, stage int, same_div bool, mut output []Group) {
	for i := lo + 1; i < hi; i++ {
		item := order[i]
		item_score := score_for(v, n, order, lo, hi, item, stage, same_div)
		mut j := i
		for j > lo {
			previous := score_for(v, n, order, lo, hi, order[j - 1], stage, same_div)
			if compare_score(item_score, previous) <= 0 { break }
			order[j] = order[j - 1]
			j--
		}
		order[j] = item
	}
	best := score_for(v, n, order, lo, hi, order[lo], stage, same_div)
	mut split := false
	for i := lo + 1; i < hi; i++ {
		if compare_score(best, score_for(v, n, order, lo, hi, order[i], stage, same_div)) != 0 { split = true }
	}
	if !split {
		output << Group{lo: lo, hi: hi, stage: stage + 1}
		return
	}
	mut start := lo
	for start < hi {
		value := score_for(v, n, order, lo, hi, order[start], stage, same_div)
		mut finish := start + 1
		for finish < hi && compare_score(value, score_for(v, n, order, lo, hi, order[finish], stage, same_div)) == 0 { finish++ }
		output << Group{lo: start, hi: finish, stage: 0}
		start = finish
	}
}

fn sweep_result(v &i64, n int, order []int, lo int, hi int) (int, int) {
	cells := n * n
	wins_start := 1 + 12 * n
	ties_start := wins_start + cells
	for position := 0; position < hi - lo; position++ {
		team := order[lo + position]
		mut win := true
		mut lose := true
		for p := lo; p < hi; p++ {
			other := order[p]
			if other == team { continue }
			won := unsafe { v[wins_start + team * n + other] }
			lost := unsafe { v[wins_start + other * n + team] }
			tied := unsafe { v[ties_start + team * n + other] }
			if won + lost + tied == 0 || tied != 0 { win = false; lose = false }
			if lost != 0 { win = false }
			if won != 0 { lose = false }
		}
		if win { return 1, position }
		if lose { return -1, position }
	}
	return 0, 0
}

@[export: 'prolangs_football_tiebreaks']
pub fn prolangs_football_tiebreaks(input &i64, length usize) i64 {
	if length < 1 { return -2 }
	n_value := unsafe { input[0] }
	if n_value < 2 || n_value > 8 { return -2 }
	n := int(n_value)
	cells := n * n
	if length != usize(1 + 12 * n + 2 * cells) { return -2 }
	mut order := []int{len: n}
	for i := 0; i < n; i++ {
		base := 1 + 12 * i
		id := unsafe { input[base] }
		if id < 0 || id > 31 || unsafe { input[base + 1] } < 0 || unsafe { input[base + 1] } > 1 || unsafe { input[base + 2] } < 0 || unsafe { input[base + 2] } > 2 { return -2 }
		for field in [3, 5, 7] {
			points := unsafe { input[base + field] }
			games := unsafe { input[base + field + 1] }
			if games < 0 || games > 64 || points < 0 || points > 2 * games { return -2 }
		}
		for field := 9; field < 12; field++ {
			value := unsafe { input[base + field] }
			if value < -4096 || value > 4096 { return -2 }
		}
		for previous := 0; previous < i; previous++ {
			if unsafe { input[1 + 12 * previous] } == id { return -2 }
		}
		order[i] = i
	}
	wins_start := 1 + 12 * n
	ties_start := wins_start + cells
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			wins := unsafe { input[wins_start + i * n + j] }
			ties := unsafe { input[ties_start + i * n + j] }
			if wins < 0 || wins > 64 || ties < 0 || ties > 64 || (i == j && (wins != 0 || ties != 0)) || ties != unsafe { input[ties_start + j * n + i] } { return -2 }
		}
	}
	for i := 1; i < n; i++ {
		item := order[i]
		mut j := i
		for j > 0 && (unsafe { input[1 + 12 * order[j - 1] + 1] } > unsafe { input[1 + 12 * item + 1] } ||
			(unsafe { input[1 + 12 * order[j - 1] + 1] } == unsafe { input[1 + 12 * item + 1] } && unsafe { input[1 + 12 * order[j - 1]] } > unsafe { input[1 + 12 * item] })) {
			order[j] = order[j - 1]
			j--
		}
		order[j] = item
	}
	mut groups := []Group{}
	groups << Group{lo: 0, hi: n, stage: 0}
	for {
		mut next := []Group{}
		mut active := false
		for group in groups {
			lo := group.lo
			hi := group.hi
			stage := group.stage
			if hi - lo <= 1 || stage >= 6 {
				next << Group{lo: lo, hi: hi, stage: 6}
				continue
			}
			active = true
			same := same_division(input, order, lo, hi)
			if stage == 0 {
				if same || hi - lo == 2 {
					refine(input, n, mut order, lo, hi, 0, same, mut next)
				} else {
					sweep_kind, sweep_position := sweep_result(input, n, order, lo, hi)
					if sweep_kind > 0 {
						position := lo + sweep_position
						tmp := order[lo]; order[lo] = order[position]; order[position] = tmp
						next << Group{lo: lo, hi: lo + 1, stage: 0}
						next << Group{lo: lo + 1, hi: hi, stage: 0}
					} else if sweep_kind < 0 {
						position := lo + sweep_position
						tmp := order[hi - 1]; order[hi - 1] = order[position]; order[position] = tmp
						next << Group{lo: lo, hi: hi - 1, stage: 0}
						next << Group{lo: hi - 1, hi: hi, stage: 0}
					} else {
						next << Group{lo: lo, hi: hi, stage: 1}
					}
				}
			} else if stage == 1 && !same {
				next << Group{lo: lo, hi: hi, stage: 2}
			} else if stage == 3 {
				mut skip_common := false
				for p := lo; p < hi; p++ { if unsafe { input[1 + 12 * order[p] + 8] } < 4 { skip_common = true } }
				if skip_common { next << Group{lo: lo, hi: hi, stage: 4} }
				else { refine(input, n, mut order, lo, hi, stage, same, mut next) }
			} else {
				refine(input, n, mut order, lo, hi, stage, same, mut next)
			}
		}
		groups = next
		if !active { break }
	}
	mut result := i64(0)
	for index in order { result = result * 32 + unsafe { input[1 + 12 * index] } }
	return result
}
