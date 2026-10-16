module problem54

const deal_count = 1000
const values_per_deal = 10

fn rank_hand(cards [5]i64) [6]i64 {
	mut ranks := [5]i64{}
	mut suits := [5]i64{}
	mut counts := [15]int{}
	for i in 0 .. 5 {
		ranks[i] = cards[i] / 4 + 2
		suits[i] = cards[i] % 4
		counts[int(ranks[i])]++
	}
	for i in 1 .. 5 {
		value := ranks[i]
		mut j := i
		for j > 0 && ranks[j - 1] < value { ranks[j] = ranks[j - 1]; j-- }
		ranks[j] = value
	}
	mut score := [6]i64{}
	mut flush := true
	for i in 1 .. 5 { if suits[i] != suits[0] { flush = false } }
	mut distinct := true
	for rank in 2 .. 15 { if counts[rank] > 1 { distinct = false } }
	mut straight_high := i64(0)
	if distinct && ranks[0] - ranks[4] == 4 { straight_high = ranks[0] }
	else if distinct && ranks[0] == 14 && ranks[1] == 5 && ranks[2] == 4 && ranks[3] == 3 && ranks[4] == 2 { straight_high = 5 }
	mut four := i64(0)
	mut three := i64(0)
	mut pair_high := i64(0)
	mut pair_low := i64(0)
	mut singles := [5]i64{}
	mut single_count := 0
	for rank := 14; rank >= 2; rank-- {
		match counts[rank] {
			4 { four = i64(rank) }
			3 { three = i64(rank) }
			2 {
				if pair_high == 0 { pair_high = i64(rank) } else { pair_low = i64(rank) }
			}
			1 { singles[single_count] = i64(rank); single_count++ }
			else {}
		}
	}
	if flush && straight_high != 0 {
		score[0] = if straight_high == 14 { i64(9) } else { i64(8) }
		score[1] = straight_high
	} else if four != 0 {
		score[0] = 7; score[1] = four; score[2] = singles[0]
	} else if three != 0 && pair_high != 0 {
		score[0] = 6; score[1] = three; score[2] = pair_high
	} else if flush {
		score[0] = 5
		for i in 0 .. 5 { score[i + 1] = ranks[i] }
	} else if straight_high != 0 {
		score[0] = 4; score[1] = straight_high
	} else if three != 0 {
		score[0] = 3; score[1] = three; score[2] = singles[0]; score[3] = singles[1]
	} else if pair_low != 0 {
		score[0] = 2; score[1] = pair_high; score[2] = pair_low; score[3] = singles[0]
	} else if pair_high != 0 {
		score[0] = 1; score[1] = pair_high; score[2] = singles[0]; score[3] = singles[1]; score[4] = singles[2]
	} else {
		score[0] = 0
		for i in 0 .. 5 { score[i + 1] = ranks[i] }
	}
	return score
}

@[export: 'problem54']
pub fn problem54(input &i64, length usize) i64 {
	if length != deal_count * values_per_deal { return -1 }
	mut wins := i64(0)
	for deal in 0 .. deal_count {
		offset := deal * values_per_deal
		for i in 0 .. values_per_deal {
			card := unsafe { input[offset + i] }
			if card < 0 || card >= 52 { return -1 }
			for previous in 0 .. i {
				if unsafe { input[offset + previous] } == card { return -1 }
			}
		}
		mut first_cards := [5]i64{}
		mut second_cards := [5]i64{}
		for i in 0 .. 5 {
			first_cards[i] = unsafe { input[offset + i] }
			second_cards[i] = unsafe { input[offset + 5 + i] }
		}
		first := rank_hand(first_cards)
		second := rank_hand(second_cards)
		for i in 0 .. 6 {
			if first[i] > second[i] { wins++; break }
			if first[i] < second[i] { break }
		}
	}
	return wins
}
