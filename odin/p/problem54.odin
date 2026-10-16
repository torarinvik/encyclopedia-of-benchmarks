package problem54

import "core:c"

rank_hand :: proc(cards: [5]i64) -> [6]i64 {
	ranks: [5]i64
	suits: [5]i64
	counts: [15]i64 = {}
	for i := 0; i < 5; i += 1 {
		ranks[i] = cards[i] / 4 + 2
		suits[i] = cards[i] % 4
		counts[int(ranks[i])] += 1
	}
	for i := 1; i < 5; i += 1 {
		value := ranks[i]
		j := i
		for j > 0 && ranks[j-1] < value { ranks[j] = ranks[j-1]; j -= 1 }
		ranks[j] = value
	}
	score: [6]i64 = {}
	flush := true
	for i := 1; i < 5; i += 1 { if suits[i] != suits[0] { flush = false } }
	distinct := true
	for rank := 2; rank <= 14; rank += 1 { if counts[rank] > 1 { distinct = false } }
	straight_high := i64(0)
	if distinct && ranks[0]-ranks[4] == 4 { straight_high = ranks[0] }
	else if distinct && ranks[0] == 14 && ranks[1] == 5 && ranks[2] == 4 && ranks[3] == 3 && ranks[4] == 2 { straight_high = 5 }
	four, three, pair_high, pair_low := i64(0), i64(0), i64(0), i64(0)
	singles: [5]i64 = {}
	single_count := 0
	for rank := 14; rank >= 2; rank -= 1 {
		switch counts[rank] {
		case 4: four = i64(rank)
		case 3: three = i64(rank)
		case 2:
			if pair_high == 0 { pair_high = i64(rank) } else { pair_low = i64(rank) }
		case 1: singles[single_count] = i64(rank); single_count += 1
		}
	}
	if flush && straight_high != 0 { score[0] = 8; if straight_high == 14 { score[0] = 9 }; score[1] = straight_high }
	else if four != 0 { score[0] = 7; score[1] = four; score[2] = singles[0] }
	else if three != 0 && pair_high != 0 { score[0] = 6; score[1] = three; score[2] = pair_high }
	else if flush { score[0] = 5; for i := 0; i < 5; i += 1 { score[i+1] = ranks[i] } }
	else if straight_high != 0 { score[0] = 4; score[1] = straight_high }
	else if three != 0 { score[0] = 3; score[1] = three; score[2] = singles[0]; score[3] = singles[1] }
	else if pair_low != 0 { score[0] = 2; score[1] = pair_high; score[2] = pair_low; score[3] = singles[0] }
	else if pair_high != 0 { score[0] = 1; score[1] = pair_high; score[2] = singles[0]; score[3] = singles[1]; score[4] = singles[2] }
	else { score[0] = 0; for i := 0; i < 5; i += 1 { score[i+1] = ranks[i] } }
	return score
}

@(export)
problem54 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != c.size_t(10_000) do return -1
	wins := i64(0)
	for deal := 0; deal < 1000; deal += 1 {
		offset := deal * 10
		for i := 0; i < 10; i += 1 {
			card := input[offset+i]
			if card < 0 || card >= 52 do return -1
			for previous := 0; previous < i; previous += 1 { if input[offset+previous] == card do return -1 }
		}
		first_cards, second_cards: [5]i64
		for i := 0; i < 5; i += 1 { first_cards[i] = input[offset+i]; second_cards[i] = input[offset+5+i] }
		first, second := rank_hand(first_cards), rank_hand(second_cards)
		for i := 0; i < 6; i += 1 {
			if first[i] > second[i] { wins += 1; break }
			if first[i] < second[i] { break }
		}
	}
	return wins
}
