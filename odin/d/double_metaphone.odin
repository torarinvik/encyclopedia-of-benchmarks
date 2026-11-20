package double_metaphone

import "core:c"

TEXT_LIMIT :: 32
PAD_BYTES :: 5
KEY_LIMIT :: 4
MAX_INPUT_LENGTH :: 34

Encoder :: struct {
	text: [TEXT_LIMIT + PAD_BYTES]u8,
	primary: [KEY_LIMIT]u8,
	secondary: [KEY_LIMIT]u8,
	length: int,
	primary_length: int,
	secondary_length: int,
	alternate_seen: bool,
}

dm_at :: proc(state: ^Encoder, index: int) -> u8 {
	if index >= 0 && index < len(state.text) do return state.text[index]
	return ' '
}

dm_has :: proc(state: ^Encoder, index: int, pattern: string) -> bool {
	if index < 0 || index + len(pattern) > len(state.text) do return false
	for offset := 0; offset < len(pattern); offset += 1 {
		if state.text[index+offset] != pattern[offset] do return false
	}
	return true
}

dm_vowel :: proc(state: ^Encoder, index: int) -> bool {
	if index < 0 || index >= state.length do return false
	ch := dm_at(state, index)
	return ch == 'A' || ch == 'E' || ch == 'I' || ch == 'O' || ch == 'U' || ch == 'Y'
}

dm_append_primary :: proc(state: ^Encoder, fragment: string) {
	for index := 0; index < len(fragment) && state.primary_length < KEY_LIMIT; index += 1 {
		state.primary[state.primary_length] = fragment[index]
		state.primary_length += 1
	}
}

dm_append_secondary :: proc(state: ^Encoder, fragment: string) {
	for index := 0; index < len(fragment) && state.secondary_length < KEY_LIMIT; index += 1 {
		state.secondary[state.secondary_length] = fragment[index]
		state.secondary_length += 1
	}
}

dm_emit :: proc(state: ^Encoder, fragment: string) {
	dm_append_primary(state, fragment)
	dm_append_secondary(state, fragment)
}

dm_emit_variant :: proc(state: ^Encoder, main, alternate: string) {
	dm_append_primary(state, main)
	if len(alternate) != 0 {
		state.alternate_seen = true
		if alternate[0] != ' ' do dm_append_secondary(state, alternate)
	} else if len(main) != 0 && main[0] != ' ' {
		dm_append_secondary(state, main)
	}
}

dm_slavo_germanic :: proc(state: ^Encoder) -> bool {
	for index := 0; index < state.length; index += 1 {
		if dm_at(state, index) == 'W' || dm_at(state, index) == 'K' ||
			dm_has(state, index, "CZ") || dm_has(state, index, "WITZ") do return true
	}
	return false
}

dm_c :: proc(state: ^Encoder, index: int) -> int {
	if index > 1 && !dm_vowel(state, index-2) && dm_has(state, index-1, "ACH") &&
		dm_at(state, index+2) != 'I' &&
		(dm_at(state, index+2) != 'E' || dm_has(state, index-2, "BACHER") || dm_has(state, index-2, "MACHER")) {
		dm_emit(state, "K"); return index + 2
	}
	if index == 0 && dm_has(state, index, "CAESAR") {
		dm_emit(state, "S"); return index + 2
	}
	if dm_has(state, index, "CHIA") {
		dm_emit(state, "K"); return index + 2
	}
	if dm_has(state, index, "CH") {
		if index > 0 && dm_has(state, index, "CHAE") {
			dm_emit_variant(state, "K", "X"); return index + 2
		}
		if index == 0 &&
			(dm_has(state, index+1, "HARAC") || dm_has(state, index+1, "HARIS") ||
			 dm_has(state, index+1, "HOR") || dm_has(state, index+1, "HYM") ||
			 dm_has(state, index+1, "HIA") || dm_has(state, index+1, "HEM")) &&
			!dm_has(state, 0, "CHORE") {
			dm_emit(state, "K"); return index + 2
		}
		hard := dm_has(state, 0, "VAN ") || dm_has(state, 0, "VON ") ||
			dm_has(state, 0, "SCH") || dm_has(state, index-2, "ORCHES") ||
			dm_has(state, index-2, "ARCHIT") || dm_has(state, index-2, "ORCHID") ||
			dm_at(state, index+2) == 'T' || dm_at(state, index+2) == 'S' ||
			((dm_at(state, index-1) == 'A' || dm_at(state, index-1) == 'O' ||
			  dm_at(state, index-1) == 'U' || dm_at(state, index-1) == 'E' || index == 0) &&
			 (dm_at(state, index+2) == 'L' || dm_at(state, index+2) == 'R' ||
			  dm_at(state, index+2) == 'N' || dm_at(state, index+2) == 'M' ||
			  dm_at(state, index+2) == 'B' || dm_at(state, index+2) == 'H' ||
			  dm_at(state, index+2) == 'F' || dm_at(state, index+2) == 'V' ||
			  dm_at(state, index+2) == 'W' || dm_at(state, index+2) == ' '))
		if hard do dm_emit(state, "K")
		else if index > 0 {
			if dm_has(state, 0, "MC") do dm_emit(state, "K")
			else do dm_emit_variant(state, "X", "K")
		} else do dm_emit(state, "X")
		return index + 2
	}
	if dm_has(state, index, "CZ") && !dm_has(state, index-2, "WICZ") {
		dm_emit_variant(state, "S", "X"); return index + 2
	}
	if dm_has(state, index+1, "CIA") {
		dm_emit(state, "X"); return index + 3
	}
	if dm_has(state, index, "CC") && !(index == 1 && dm_at(state, 0) == 'M') {
		if (dm_at(state, index+2) == 'I' || dm_at(state, index+2) == 'E' ||
			dm_at(state, index+2) == 'H') && !dm_has(state, index+2, "HU") {
			if (index == 1 && dm_at(state, index-1) == 'A') ||
				dm_has(state, index-1, "UCCEE") || dm_has(state, index-1, "UCCES") {
				dm_emit(state, "KS")
			} else do dm_emit(state, "X")
			return index + 3
		}
		dm_emit(state, "K"); return index + 2
	}
	if dm_has(state, index, "CK") || dm_has(state, index, "CG") || dm_has(state, index, "CQ") {
		dm_emit(state, "K"); return index + 2
	}
	if dm_has(state, index, "CI") || dm_has(state, index, "CE") || dm_has(state, index, "CY") {
		if dm_has(state, index, "CIO") || dm_has(state, index, "CIE") || dm_has(state, index, "CIA")
			dm_emit_variant(state, "S", "X")
		else do dm_emit(state, "S")
		return index + 2
	}
	dm_emit(state, "K")
	if dm_has(state, index+1, " C") || dm_has(state, index+1, " Q") || dm_has(state, index+1, " G") do return index + 3
	if (dm_at(state, index+1) == 'C' || dm_at(state, index+1) == 'K' || dm_at(state, index+1) == 'Q') &&
		!dm_has(state, index+1, "CE") && !dm_has(state, index+1, "CI") do return index + 2
	return index + 1
}

dm_g :: proc(state: ^Encoder, index: int, slavo: bool) -> int {
	if dm_at(state, index+1) == 'H' {
		if index > 0 && !dm_vowel(state, index-1) {
			dm_emit(state, "K"); return index + 2
		}
		if index == 0 {
			if dm_at(state, index+2) == 'I' do dm_emit(state, "J") else do dm_emit(state, "K")
			return index + 2
		}
		silent := (index > 1 && (dm_at(state, index-2) == 'B' || dm_at(state, index-2) == 'H' || dm_at(state, index-2) == 'D')) ||
			(index > 2 && (dm_at(state, index-3) == 'B' || dm_at(state, index-3) == 'H' || dm_at(state, index-3) == 'D')) ||
			(index > 3 && (dm_at(state, index-4) == 'B' || dm_at(state, index-4) == 'H'))
		if silent do return index + 2
		if index > 2 && dm_at(state, index-1) == 'U' &&
			(dm_at(state, index-3) == 'C' || dm_at(state, index-3) == 'G' || dm_at(state, index-3) == 'L' ||
			 dm_at(state, index-3) == 'R' || dm_at(state, index-3) == 'T') do dm_emit(state, "F")
		else if index > 0 && dm_at(state, index-1) != 'I' do dm_emit(state, "K")
		return index + 2
	}
	if dm_at(state, index+1) == 'N' {
		if index == 1 && dm_vowel(state, 0) && !slavo do dm_emit_variant(state, "KN", "N")
		else if !dm_has(state, index+2, "EY") && dm_at(state, index+1) != 'Y' && !slavo do dm_emit_variant(state, "N", "KN")
		else do dm_emit(state, "KN")
		return index + 2
	}
	if dm_has(state, index+1, "LI") && !slavo {
		dm_emit_variant(state, "KL", "L"); return index + 2
	}
	if index == 0 && (dm_at(state, index+1) == 'Y' ||
		dm_has(state, index+1, "ES") || dm_has(state, index+1, "EP") ||
		dm_has(state, index+1, "EB") || dm_has(state, index+1, "EL") ||
		dm_has(state, index+1, "EY") || dm_has(state, index+1, "IB") ||
		dm_has(state, index+1, "IL") || dm_has(state, index+1, "IN") ||
		dm_has(state, index+1, "IE") || dm_has(state, index+1, "EI") ||
		dm_has(state, index+1, "ER")) {
		dm_emit_variant(state, "K", "J"); return index + 2
	}
	if (dm_has(state, index+1, "ER") || dm_at(state, index+1) == 'Y') &&
		!dm_has(state, 0, "DANGER") && !dm_has(state, 0, "RANGER") && !dm_has(state, 0, "MANGER") &&
		dm_at(state, index-1) != 'E' && dm_at(state, index-1) != 'I' &&
		!dm_has(state, index-1, "RGY") && !dm_has(state, index-1, "OGY") {
		dm_emit_variant(state, "K", "J"); return index + 2
	}
	if dm_at(state, index+1) == 'E' || dm_at(state, index+1) == 'I' ||
		dm_at(state, index+1) == 'Y' || dm_has(state, index-1, "AGGI") || dm_has(state, index-1, "OGGI") {
		if dm_has(state, 0, "VAN ") || dm_has(state, 0, "VON ") || dm_has(state, 0, "SCH") || dm_has(state, index+1, "ET") do dm_emit(state, "K")
		else if dm_has(state, index+1, "IER ") do dm_emit(state, "J")
		else do dm_emit_variant(state, "J", "K")
		return index + 2
	}
	dm_emit(state, "K")
	if dm_at(state, index+1) == 'G' do return index + 2
	return index + 1
}

dm_j :: proc(state: ^Encoder, index: int, slavo: bool) -> int {
	if dm_has(state, index, "JOSE") || dm_has(state, 0, "SAN ") {
		if (index == 0 && dm_at(state, index+4) == ' ') || dm_has(state, 0, "SAN ") do dm_emit(state, "H")
		else do dm_emit_variant(state, "J", "H")
		return index + 1
	}
	if index == 0 do dm_emit_variant(state, "J", "A")
	else if dm_vowel(state, index-1) && !slavo && (dm_at(state, index+1) == 'A' || dm_at(state, index+1) == 'O') do dm_emit_variant(state, "J", "H")
	else if index == state.length-1 do dm_emit_variant(state, "J", " ")
	else if !(dm_at(state, index+1) == 'L' || dm_at(state, index+1) == 'T' ||
		dm_at(state, index+1) == 'K' || dm_at(state, index+1) == 'S' ||
		dm_at(state, index+1) == 'N' || dm_at(state, index+1) == 'M' ||
		dm_at(state, index+1) == 'B' || dm_at(state, index+1) == 'Z') &&
		dm_at(state, index-1) != 'S' && dm_at(state, index-1) != 'K' && dm_at(state, index-1) != 'L' do dm_emit(state, "J")
	return index + (if dm_at(state, index+1) == 'J' then 2 else 1)
}

dm_l :: proc(state: ^Encoder, index: int) -> int {
	if dm_at(state, index+1) != 'L' {
		dm_emit(state, "L"); return index + 1
	}
	spanish := (index == state.length-3 &&
		(dm_has(state, index-1, "ILLO") || dm_has(state, index-1, "ILLA") || dm_has(state, index-1, "ALLE"))) ||
		((dm_has(state, state.length-3, "AS") || dm_has(state, state.length-3, "OS") ||
		  dm_at(state, state.length-1) == 'A' || dm_at(state, state.length-1) == 'O') && dm_has(state, index-1, "ALLE"))
	if spanish do dm_emit_variant(state, "L", " ") else do dm_emit(state, "L")
	return index + 2
}

dm_s :: proc(state: ^Encoder, index: int, slavo: bool) -> int {
	if dm_has(state, index-1, "ISL") || dm_has(state, index-1, "YSL") do return index + 1
	if index == 0 && dm_has(state, index, "SUGAR") {
		dm_emit_variant(state, "X", "S"); return index + 1
	}
	if dm_has(state, index, "SH") {
		if dm_has(state, index+1, "HEIM") || dm_has(state, index+1, "HOEK") ||
			dm_has(state, index+1, "HOLM") || dm_has(state, index+1, "HOLZ") do dm_emit(state, "S")
		else do dm_emit(state, "X")
		return index + 2
	}
	if dm_has(state, index, "SIO") || dm_has(state, index, "SIA") || dm_has(state, index, "SIAN") {
		if !slavo do dm_emit_variant(state, "S", "X") else do dm_emit(state, "S")
		return index + 3
	}
	if (index == 0 && (dm_at(state, index+1) == 'M' || dm_at(state, index+1) == 'N' ||
		dm_at(state, index+1) == 'L' || dm_at(state, index+1) == 'W')) || dm_at(state, index+1) == 'Z' {
		dm_emit_variant(state, "S", "X")
		return index + (if dm_at(state, index+1) == 'Z' then 2 else 1)
	}
	if dm_has(state, index, "SC") {
		if dm_at(state, index+2) == 'H' {
			if dm_has(state, index+3, "OO") || dm_has(state, index+3, "ER") ||
				dm_has(state, index+3, "EN") || dm_has(state, index+3, "UY") ||
				dm_has(state, index+3, "ED") || dm_has(state, index+3, "EM") {
				if dm_has(state, index+3, "ER") || dm_has(state, index+3, "EN") do dm_emit_variant(state, "X", "SK")
				else do dm_emit(state, "SK")
			} else if index == 0 && !dm_vowel(state, 3) && dm_at(state, 3) != 'W' do dm_emit_variant(state, "X", "S")
			else do dm_emit(state, "X")
			return index + 3
		}
		if dm_at(state, index+2) == 'I' || dm_at(state, index+2) == 'E' || dm_at(state, index+2) == 'Y' do dm_emit(state, "S")
		else do dm_emit(state, "SK")
		return index + 3
	}
	if index == state.length-1 && (dm_has(state, index-2, "AI") || dm_has(state, index-2, "OI")) do dm_emit_variant(state, "", "S")
	else do dm_emit(state, "S")
	if dm_at(state, index+1) == 'S' || dm_at(state, index+1) == 'Z' do return index + 2
	return index + 1
}

dm_t :: proc(state: ^Encoder, index: int) -> int {
	if dm_has(state, index, "TION") { dm_emit(state, "X"); return index + 3 }
	if dm_has(state, index, "TIA") || dm_has(state, index, "TCH") { dm_emit(state, "X"); return index + 3 }
	if dm_has(state, index, "TH") || dm_has(state, index, "TTH") {
		if dm_has(state, index+2, "OM") || dm_has(state, index+2, "AM") ||
			dm_has(state, 0, "VAN ") || dm_has(state, 0, "VON ") || dm_has(state, 0, "SCH") do dm_emit(state, "T")
		else do dm_emit_variant(state, "0", "T")
		return index + 2
	}
	dm_emit(state, "T")
	if dm_at(state, index+1) == 'T' || dm_at(state, index+1) == 'D' do return index + 2
	return index + 1
}

dm_w :: proc(state: ^Encoder, index: int) -> int {
	if dm_has(state, index, "WR") { dm_emit(state, "R"); return index + 2 }
	if index == 0 && (dm_vowel(state, index+1) || dm_has(state, index, "WH")) {
		if dm_vowel(state, index+1) do dm_emit_variant(state, "A", "F") else do dm_emit(state, "A")
	}
	if (index == state.length-1 && dm_vowel(state, index-1)) ||
		dm_has(state, index-1, "EWSKI") || dm_has(state, index-1, "EWSKY") ||
		dm_has(state, index-1, "OWSKI") || dm_has(state, index-1, "OWSKY") || dm_has(state, 0, "SCH") {
		dm_emit_variant(state, "", "F"); return index + 1
	}
	if dm_has(state, index, "WICZ") || dm_has(state, index, "WITZ") {
		dm_emit_variant(state, "TS", "FX"); return index + 4
	}
	return index + 1
}

dm_x :: proc(state: ^Encoder, index: int) -> int {
	french_end := index == state.length-1 &&
		(dm_has(state, index-3, "IAU") || dm_has(state, index-3, "EAU") ||
		 dm_has(state, index-2, "AU") || dm_has(state, index-2, "OU"))
	if !french_end do dm_emit(state, "KS")
	if dm_at(state, index+1) == 'C' || dm_at(state, index+1) == 'X' do return index + 2
	return index + 1
}

dm_z :: proc(state: ^Encoder, index: int, slavo: bool) -> int {
	if dm_at(state, index+1) == 'H' { dm_emit(state, "J"); return index + 2 }
	if dm_has(state, index+1, "ZO") || dm_has(state, index+1, "ZI") || dm_has(state, index+1, "ZA") ||
		(slavo && index > 0 && dm_at(state, index-1) != 'T') do dm_emit_variant(state, "S", "TS")
	else do dm_emit(state, "S")
	if dm_at(state, index+1) == 'Z' do return index + 2
	return index + 1
}

dm_upper :: proc(value: i64) -> u8 {
	if value >= 'a' && value <= 'z' do return u8(value - ('a' - 'A'))
	if value == 0xE7 do return 0xC7
	if value == 0xF1 do return 0xD1
	return u8(value)
}

@(export)
double_metaphone :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > TEXT_LIMIT do return -1
	count := int(input[0])
	if length != c.size_t(count+1) do return -1

	state := Encoder{}
	for index := 0; index < len(state.text); index += 1 { state.text[index] = ' ' }
	state.length = count
	for index := 0; index < count; index += 1 {
		raw := input[index+1]
		if !((raw >= 'A' && raw <= 'Z') || (raw >= 'a' && raw <= 'z') || raw == ' ' ||
			raw == 0xC7 || raw == 0xE7 || raw == 0xD1 || raw == 0xF1) do return -1
		state.text[index] = dm_upper(raw)
	}

	slavo := dm_slavo_germanic(&state)
	index := 0
	if dm_has(&state, 0, "GN") || dm_has(&state, 0, "KN") || dm_has(&state, 0, "PN") ||
		dm_has(&state, 0, "WR") || dm_has(&state, 0, "PS") do index = 1
	if dm_at(&state, 0) == 'X' { dm_emit(&state, "S"); index = 1 }

	for index < state.length && (state.primary_length < KEY_LIMIT || state.secondary_length < KEY_LIMIT) {
		switch dm_at(&state, index) {
		case 'A', 'E', 'I', 'O', 'U', 'Y':
			if index == 0 do dm_emit(&state, "A")
			index += 1
		case 'B':
			dm_emit(&state, "P")
			if dm_at(&state, index+1) == 'B' do index += 2 else do index += 1
		case 0xC7:
			dm_emit(&state, "S"); index += 1
		case 'C': index = dm_c(&state, index)
		case 'D':
			if dm_has(&state, index, "DG") {
				if dm_at(&state, index+2) == 'I' || dm_at(&state, index+2) == 'E' || dm_at(&state, index+2) == 'Y' {
					dm_emit(&state, "J"); index += 3
				} else { dm_emit(&state, "TK"); index += 2 }
			} else if dm_has(&state, index, "DT") || dm_has(&state, index, "DD") {
				dm_emit(&state, "T"); index += 2
			} else { dm_emit(&state, "T"); index += 1 }
		case 'F':
			dm_emit(&state, "F")
			if dm_at(&state, index+1) == 'F' do index += 2 else do index += 1
		case 'G': index = dm_g(&state, index, slavo)
		case 'H':
			if (index == 0 || dm_vowel(&state, index-1)) && dm_vowel(&state, index+1) {
				dm_emit(&state, "H"); index += 2
			} else do index += 1
		case 'J': index = dm_j(&state, index, slavo)
		case 'K':
			dm_emit(&state, "K")
			if dm_at(&state, index+1) == 'K' do index += 2 else do index += 1
		case 'L': index = dm_l(&state, index)
		case 'M':
			if (dm_has(&state, index-1, "UMB") &&
				(index+1 == state.length-1 || dm_has(&state, index+2, "ER"))) || dm_at(&state, index+1) == 'M' do index += 2
			else do index += 1
			dm_emit(&state, "M")
		case 'N':
			dm_emit(&state, "N")
			if dm_at(&state, index+1) == 'N' do index += 2 else do index += 1
		case 0xD1:
			dm_emit(&state, "N"); index += 1
		case 'P':
			if dm_at(&state, index+1) == 'H' { dm_emit(&state, "F"); index += 2 }
			else {
				dm_emit(&state, "P")
				if dm_at(&state, index+1) == 'P' || dm_at(&state, index+1) == 'B' do index += 2 else do index += 1
			}
		case 'Q':
			dm_emit(&state, "K")
			if dm_at(&state, index+1) == 'Q' do index += 2 else do index += 1
		case 'R':
			if index == state.length-1 && !slavo && dm_has(&state, index-2, "IE") &&
				!dm_has(&state, index-4, "ME") && !dm_has(&state, index-4, "MA") do dm_emit_variant(&state, "", "R")
			else do dm_emit(&state, "R")
			if dm_at(&state, index+1) == 'R' do index += 2 else do index += 1
		case 'S': index = dm_s(&state, index, slavo)
		case 'T': index = dm_t(&state, index)
		case 'V':
			dm_emit(&state, "F")
			if dm_at(&state, index+1) == 'V' do index += 2 else do index += 1
		case 'W': index = dm_w(&state, index)
		case 'X': index = dm_x(&state, index)
		case 'Z': index = dm_z(&state, index, slavo)
		case: index += 1
		}
	}

	secondary_length := 0
	if state.alternate_seen do secondary_length = state.secondary_length
	if secondary_length == state.primary_length {
		equal := true
		for offset := 0; offset < state.primary_length; offset += 1 {
			if state.primary[offset] != state.secondary[offset] do equal = false
		}
		if equal do secondary_length = 0
	}
	required := 2 + state.primary_length + secondary_length
	if output == nil || capacity < c.size_t(required) do return -2
	output[0] = u8(state.primary_length)
	output[1] = u8(secondary_length)
	for offset := 0; offset < state.primary_length; offset += 1 { output[2+offset] = state.primary[offset] }
	for offset := 0; offset < secondary_length; offset += 1 {
		output[2+state.primary_length+offset] = state.secondary[offset]
	}
	return i64(required)
}
