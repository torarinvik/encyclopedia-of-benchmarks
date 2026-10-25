package prolangs_football_tiebreaks
import "core:c"

Fraction :: struct { numerator: i64, denominator: i64 }
Group :: struct { lo: int, hi: int, stage: int }

same_division :: proc(v: [^]i64, order: ^[8]int, lo, hi: int) -> bool {
	first := 1 + 12*order[lo]
	for p in lo+1..<hi {
		current := 1 + 12*order[p]
		if v[first+1] != v[current+1] || v[first+2] != v[current+2] { return false }
	}
	return true
}

score_for :: proc(v: [^]i64, n: int, order: ^[8]int, lo, hi, team, stage: int, same_div: bool) -> Fraction {
	if stage == 0 {
		cells := n*n; wins_start := 1+12*n; ties_start := wins_start+cells
		won, lost, tied: i64 = 0, 0, 0
		for p in lo..<hi {
			other := order[p]; if other == team { continue }
			won += v[wins_start+team*n+other]; lost += v[wins_start+other*n+team]
			tied += v[ties_start+team*n+other]
		}
		games := won+lost+tied; denominator := 2*games; if games == 0 { denominator = 1 }
		return Fraction{2*won+tied, denominator}
	}
	base := 1+12*team
	if stage >= 1 && stage <= 3 {
		field := 7; if stage == 1 { field = 3 } else if stage == 2 { field = 5 }
		games := v[base+field+1]; denominator := 2*games; if games == 0 { denominator = 1 }
		return Fraction{v[base+field], denominator}
	}
	if stage == 4 { field := 10; if same_div { field = 9 }; return Fraction{v[base+field], 1} }
	return Fraction{v[base+11], 1}
}

compare_score :: proc(a, b: Fraction) -> int {
	left := a.numerator*b.denominator; right := b.numerator*a.denominator
	if left > right { return 1 }; if left < right { return -1 }; return 0
}

refine :: proc(v: [^]i64, n: int, order: ^[8]int, lo, hi, stage: int, same_div: bool,
		output: ^[8]Group, output_count: ^int) {
	for i in lo+1..<hi {
		item := order[i]; item_score := score_for(v,n,order,lo,hi,item,stage,same_div); j := i
		for j > lo {
			previous := score_for(v,n,order,lo,hi,order[j-1],stage,same_div)
			if compare_score(item_score,previous) <= 0 { break }
			order[j] = order[j-1]; j -= 1
		}
		order[j] = item
	}
	best := score_for(v,n,order,lo,hi,order[lo],stage,same_div); split := false
	for i in lo+1..<hi { if compare_score(best,score_for(v,n,order,lo,hi,order[i],stage,same_div)) != 0 { split = true } }
	if !split { output[output_count^] = Group{lo,hi,stage+1}; output_count^ += 1; return }
	start := lo
	for start < hi {
		value := score_for(v,n,order,lo,hi,order[start],stage,same_div); finish := start+1
		for finish < hi && compare_score(value,score_for(v,n,order,lo,hi,order[finish],stage,same_div)) == 0 { finish += 1 }
		output[output_count^] = Group{start,finish,0}; output_count^ += 1; start = finish
	}
}

sweep_result :: proc(v: [^]i64, n: int, order: ^[8]int, lo, hi: int) -> int {
	cells := n*n; wins_start := 1+12*n; ties_start := wins_start+cells
	for position in 0..<hi-lo {
		team := order[lo+position]; win := true; lose := true
		for p in lo..<hi {
			other := order[p]; if other == team { continue }
			won := v[wins_start+team*n+other]; lost := v[wins_start+other*n+team]; tied := v[ties_start+team*n+other]
			if won+lost+tied == 0 || tied != 0 { win = false; lose = false }
			if lost != 0 { win = false }; if won != 0 { lose = false }
		}
		if win { return position+1 }; if lose { return -(position+1) }
	}
	return 0
}

@(export)
prolangs_football_tiebreaks :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 2 || input[0] > 8 { return -2 }
	n := int(input[0]); cells := n*n
	if length != c.size_t(1+12*n+2*cells) { return -2 }
	order: [8]int
	for i in 0..<n {
		base := 1+12*i; id := input[base]
		if id < 0 || id > 31 || input[base+1] < 0 || input[base+1] > 1 || input[base+2] < 0 || input[base+2] > 2 { return -2 }
		for f in [3,5,7] { points := input[base+f]; games := input[base+f+1]; if games < 0 || games > 64 || points < 0 || points > 2*games { return -2 } }
		for f in 9..<12 { if input[base+f] < -4096 || input[base+f] > 4096 { return -2 } }
		for j in 0..<i { if input[1+12*j] == id { return -2 } }
		order[i] = i
	}
	wins_start := 1+12*n; ties_start := wins_start+cells
	for i in 0..<n { for j in 0..<n {
		wins := input[wins_start+i*n+j]; ties := input[ties_start+i*n+j]
		if wins < 0 || wins > 64 || ties < 0 || ties > 64 || (i == j && (wins != 0 || ties != 0)) || ties != input[ties_start+j*n+i] { return -2 }
	} }
	for i in 1..<n {
		item := order[i]; j := i
		for j > 0 && (input[1+12*order[j-1]+1] > input[1+12*item+1] ||
			(input[1+12*order[j-1]+1] == input[1+12*item+1] && input[1+12*order[j-1]] > input[1+12*item])) { order[j] = order[j-1]; j -= 1 }
		order[j] = item
	}
	groups: [8]Group; next: [8]Group; group_count := 1; groups[0] = Group{0,n,0}
	for {
		next_count := 0; active := false
		for g in 0..<group_count {
			lo := groups[g].lo; hi := groups[g].hi; stage := groups[g].stage
			if hi-lo <= 1 || stage >= 6 { next[next_count] = Group{lo,hi,6}; next_count += 1; continue }
			active = true; same := same_division(input,&order,lo,hi)
			if stage == 0 {
				if same || hi-lo == 2 { refine(input,n,&order,lo,hi,0,same,&next,&next_count) }
				else {
					sweep := sweep_result(input,n,&order,lo,hi)
					if sweep > 0 { p := lo+sweep-1; tmp := order[lo]; order[lo] = order[p]; order[p] = tmp; next[next_count] = Group{lo,lo+1,0}; next_count += 1; next[next_count] = Group{lo+1,hi,0}; next_count += 1 }
					else if sweep < 0 { p := lo-sweep-1; tmp := order[hi-1]; order[hi-1] = order[p]; order[p] = tmp; next[next_count] = Group{lo,hi-1,0}; next_count += 1; next[next_count] = Group{hi-1,hi,0}; next_count += 1 }
					else { next[next_count] = Group{lo,hi,1}; next_count += 1 }
				}
			} else if stage == 1 && !same { next[next_count] = Group{lo,hi,2}; next_count += 1 }
			else if stage == 3 {
				skip_common := false; for p in lo..<hi { if input[1+12*order[p]+8] < 4 { skip_common = true } }
				if skip_common { next[next_count] = Group{lo,hi,4}; next_count += 1 } else { refine(input,n,&order,lo,hi,stage,same,&next,&next_count) }
			} else { refine(input,n,&order,lo,hi,stage,same,&next,&next_count) }
		}
		for g in 0..<next_count { groups[g] = next[g] }; group_count = next_count
		if !active { break }
	}
	result: i64 = 0
	for i in 0..<n { result = result*32 + input[1+12*order[i]] }
	return result
}
