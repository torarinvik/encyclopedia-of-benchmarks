module double_metaphone

const text_limit = 32
const pad = 5
const key_limit = 4

struct Encoder {
mut:
	text [37]u8
	primary [4]u8
	secondary [4]u8
	length int
	primary_len int
	secondary_len int
	alternate_seen bool
}

fn at(s &Encoder, i int) u8 {
	if i < 0 || i >= text_limit + pad { return u8(` `) }
	return s.text[i]
}

fn has(s &Encoder, i int, pattern string) bool {
	if i < 0 || i + pattern.len > text_limit + pad { return false }
	for j in 0 .. pattern.len {
		if s.text[i + j] != pattern[j] { return false }
	}
	return true
}

fn vowel(s &Encoder, i int) bool {
	if i < 0 || i >= s.length { return false }
	c := at(s, i)
	return c == u8(`A`) || c == u8(`E`) || c == u8(`I`) || c == u8(`O`) || c == u8(`U`) || c == u8(`Y`)
}

fn append(mut target [4]u8, mut size int, fragment string) {
	for j in 0 .. fragment.len {
		if size >= key_limit { break }
		target[size] = fragment[j]
		size++
	}
}

fn same(mut s Encoder, value string) {
	append(mut s.primary, mut s.primary_len, value)
	append(mut s.secondary, mut s.secondary_len, value)
}

fn choice(mut s Encoder, main string, alt string) {
	append(mut s.primary, mut s.primary_len, main)
	if alt.len > 0 {
		s.alternate_seen = true
		if alt[0] != ` ` { append(mut s.secondary, mut s.secondary_len, alt) }
	} else if main.len > 0 && main[0] != ` ` {
		append(mut s.secondary, mut s.secondary_len, main)
	}
}

fn slavo(s &Encoder) bool {
	for i in 0 .. s.length {
		if at(s, i) == u8(`W`) || at(s, i) == u8(`K`) || has(s, i, 'CZ') || has(s, i, 'WITZ') { return true }
	}
	return false
}

fn rule_c(mut s Encoder, i int) int {
	if i > 1 && !vowel(s, i - 2) && has(s, i - 1, 'ACH') && at(s, i + 2) != u8(`I`) &&
		(at(s, i + 2) != u8(`E`) || has(s, i - 2, 'BACHER') || has(s, i - 2, 'MACHER')) {
		same(mut s, 'K'); return i + 2
	}
	if i == 0 && has(s, i, 'CAESAR') { same(mut s, 'S'); return i + 2 }
	if has(s, i, 'CHIA') { same(mut s, 'K'); return i + 2 }
	if has(s, i, 'CH') {
		if i > 0 && has(s, i, 'CHAE') { choice(mut s, 'K', 'X'); return i + 2 }
		if i == 0 && (has(s, i + 1, 'HARAC') || has(s, i + 1, 'HARIS') || has(s, i + 1, 'HOR') ||
			has(s, i + 1, 'HYM') || has(s, i + 1, 'HIA') || has(s, i + 1, 'HEM')) && !has(s, 0, 'CHORE') {
			same(mut s, 'K'); return i + 2
		}
		hard := has(s, 0, 'VAN ') || has(s, 0, 'VON ') || has(s, 0, 'SCH') || has(s, i - 2, 'ORCHES') ||
			has(s, i - 2, 'ARCHIT') || has(s, i - 2, 'ORCHID') || at(s, i + 2) == u8(`T`) || at(s, i + 2) == u8(`S`) ||
			((at(s, i - 1) == u8(`A`) || at(s, i - 1) == u8(`O`) || at(s, i - 1) == u8(`U`) || at(s, i - 1) == u8(`E`) || i == 0) &&
			(at(s, i + 2) == u8(`L`) || at(s, i + 2) == u8(`R`) || at(s, i + 2) == u8(`N`) || at(s, i + 2) == u8(`M`) ||
			 at(s, i + 2) == u8(`B`) || at(s, i + 2) == u8(`H`) || at(s, i + 2) == u8(`F`) || at(s, i + 2) == u8(`V`) ||
			 at(s, i + 2) == u8(`W`) || at(s, i + 2) == u8(` `)))
		if hard { same(mut s, 'K') }
		else if i > 0 { if has(s, 0, 'MC') { same(mut s, 'K') } else { choice(mut s, 'X', 'K') } }
		else { same(mut s, 'X') }
		return i + 2
	}
	if has(s, i, 'CZ') && !has(s, i - 2, 'WICZ') { choice(mut s, 'S', 'X'); return i + 2 }
	if has(s, i + 1, 'CIA') { same(mut s, 'X'); return i + 3 }
	if has(s, i, 'CC') && !(i == 1 && at(s, 0) == u8(`M`)) {
		if (at(s, i + 2) == u8(`I`) || at(s, i + 2) == u8(`E`) || at(s, i + 2) == u8(`H`)) && !has(s, i + 2, 'HU') {
			if (i == 1 && at(s, i - 1) == u8(`A`)) || has(s, i - 1, 'UCCEE') || has(s, i - 1, 'UCCES') { same(mut s, 'KS') }
			else { same(mut s, 'X') }
			return i + 3
		}
		same(mut s, 'K'); return i + 2
	}
	if has(s, i, 'CK') || has(s, i, 'CG') || has(s, i, 'CQ') { same(mut s, 'K'); return i + 2 }
	if has(s, i, 'CI') || has(s, i, 'CE') || has(s, i, 'CY') {
		if has(s, i, 'CIO') || has(s, i, 'CIE') || has(s, i, 'CIA') { choice(mut s, 'S', 'X') }
		else { same(mut s, 'S') }
		return i + 2
	}
	same(mut s, 'K')
	if has(s, i + 1, ' C') || has(s, i + 1, ' Q') || has(s, i + 1, ' G') { return i + 3 }
	if (at(s, i + 1) == u8(`C`) || at(s, i + 1) == u8(`K`) || at(s, i + 1) == u8(`Q`)) && !has(s, i + 1, 'CE') && !has(s, i + 1, 'CI') { return i + 2 }
	return i + 1
}

fn rule_g(mut s Encoder, i int, germanic bool) int {
	if at(s, i + 1) == u8(`H`) {
		if i > 0 && !vowel(s, i - 1) { same(mut s, 'K'); return i + 2 }
		if i == 0 { if at(s, i + 2) == u8(`I`) { same(mut s, 'J') } else { same(mut s, 'K') }; return i + 2 }
		if (i > 1 && (at(s, i - 2) == u8(`B`) || at(s, i - 2) == u8(`H`) || at(s, i - 2) == u8(`D`))) ||
			(i > 2 && (at(s, i - 3) == u8(`B`) || at(s, i - 3) == u8(`H`) || at(s, i - 3) == u8(`D`))) ||
			(i > 3 && (at(s, i - 4) == u8(`B`) || at(s, i - 4) == u8(`H`))) { return i + 2 }
		if i > 2 && at(s, i - 1) == u8(`U`) && (at(s, i - 3) == u8(`C`) || at(s, i - 3) == u8(`G`) || at(s, i - 3) == u8(`L`) || at(s, i - 3) == u8(`R`) || at(s, i - 3) == u8(`T`)) { same(mut s, 'F') }
		else if i > 0 && at(s, i - 1) != u8(`I`) { same(mut s, 'K') }
		return i + 2
	}
	if at(s, i + 1) == u8(`N`) {
		if i == 1 && vowel(s, 0) && !germanic { choice(mut s, 'KN', 'N') }
		else if !has(s, i + 2, 'EY') && at(s, i + 1) != u8(`Y`) && !germanic { choice(mut s, 'N', 'KN') }
		else { same(mut s, 'KN') }
		return i + 2
	}
	if has(s, i + 1, 'LI') && !germanic { choice(mut s, 'KL', 'L'); return i + 2 }
	if i == 0 && (at(s, i + 1) == u8(`Y`) || has(s, i + 1, 'ES') || has(s, i + 1, 'EP') || has(s, i + 1, 'EB') || has(s, i + 1, 'EL') || has(s, i + 1, 'EY') || has(s, i + 1, 'IB') || has(s, i + 1, 'IL') || has(s, i + 1, 'IN') || has(s, i + 1, 'IE') || has(s, i + 1, 'EI') || has(s, i + 1, 'ER')) { choice(mut s, 'K', 'J'); return i + 2 }
	if (has(s, i + 1, 'ER') || at(s, i + 1) == u8(`Y`)) && !has(s, 0, 'DANGER') && !has(s, 0, 'RANGER') && !has(s, 0, 'MANGER') && at(s, i - 1) != u8(`E`) && at(s, i - 1) != u8(`I`) && !has(s, i - 1, 'RGY') && !has(s, i - 1, 'OGY') { choice(mut s, 'K', 'J'); return i + 2 }
	if at(s, i + 1) == u8(`E`) || at(s, i + 1) == u8(`I`) || at(s, i + 1) == u8(`Y`) || has(s, i - 1, 'AGGI') || has(s, i - 1, 'OGGI') {
		if has(s, 0, 'VAN ') || has(s, 0, 'VON ') || has(s, 0, 'SCH') || has(s, i + 1, 'ET') { same(mut s, 'K') }
		else if has(s, i + 1, 'IER ') { same(mut s, 'J') }
		else { choice(mut s, 'J', 'K') }
		return i + 2
	}
	same(mut s, 'K')
	return i + if at(s, i + 1) == u8(`G`) { 2 } else { 1 }
}

fn rule_j(mut s Encoder, i int, germanic bool) int {
	if has(s, i, 'JOSE') || has(s, 0, 'SAN ') { if (i == 0 && at(s, i + 4) == u8(` `)) || has(s, 0, 'SAN ') { same(mut s, 'H') } else { choice(mut s, 'J', 'H') }; return i + 1 }
	if i == 0 { choice(mut s, 'J', 'A') }
	else if vowel(s, i - 1) && !germanic && (at(s, i + 1) == u8(`A`) || at(s, i + 1) == u8(`O`)) { choice(mut s, 'J', 'H') }
	else if i == s.length - 1 { choice(mut s, 'J', ' ') }
	else if !(at(s, i + 1) == u8(`L`) || at(s, i + 1) == u8(`T`) || at(s, i + 1) == u8(`K`) || at(s, i + 1) == u8(`S`) || at(s, i + 1) == u8(`N`) || at(s, i + 1) == u8(`M`) || at(s, i + 1) == u8(`B`) || at(s, i + 1) == u8(`Z`)) && at(s, i - 1) != u8(`S`) && at(s, i - 1) != u8(`K`) && at(s, i - 1) != u8(`L`) { same(mut s, 'J') }
	return i + if at(s, i + 1) == u8(`J`) { 2 } else { 1 }
}

fn rule_l(mut s Encoder, i int) int {
	if at(s, i + 1) != u8(`L`) { same(mut s, 'L'); return i + 1 }
	n := s.length
	spanish := (i == n - 3 && (has(s, i - 1, 'ILLO') || has(s, i - 1, 'ILLA') || has(s, i - 1, 'ALLE'))) || ((has(s, n - 3, 'AS') || has(s, n - 3, 'OS') || at(s, n - 1) == u8(`A`) || at(s, n - 1) == u8(`O`)) && has(s, i - 1, 'ALLE'))
	if spanish { choice(mut s, 'L', ' ') } else { same(mut s, 'L') }
	return i + 2
}

fn rule_s(mut s Encoder, i int, germanic bool) int {
	if has(s, i - 1, 'ISL') || has(s, i - 1, 'YSL') { return i + 1 }
	if i == 0 && has(s, i, 'SUGAR') { choice(mut s, 'X', 'S'); return i + 1 }
	if has(s, i, 'SH') { if has(s, i + 1, 'HEIM') || has(s, i + 1, 'HOEK') || has(s, i + 1, 'HOLM') || has(s, i + 1, 'HOLZ') { same(mut s, 'S') } else { same(mut s, 'X') }; return i + 2 }
	if has(s, i, 'SIO') || has(s, i, 'SIA') || has(s, i, 'SIAN') { if !germanic { choice(mut s, 'S', 'X') } else { same(mut s, 'S') }; return i + 3 }
	if (i == 0 && (at(s, i + 1) == u8(`M`) || at(s, i + 1) == u8(`N`) || at(s, i + 1) == u8(`L`) || at(s, i + 1) == u8(`W`))) || at(s, i + 1) == u8(`Z`) { choice(mut s, 'S', 'X'); return i + if at(s, i + 1) == u8(`Z`) { 2 } else { 1 } }
	if has(s, i, 'SC') {
		if at(s, i + 2) == u8(`H`) {
			if has(s, i + 3, 'OO') || has(s, i + 3, 'ER') || has(s, i + 3, 'EN') || has(s, i + 3, 'UY') || has(s, i + 3, 'ED') || has(s, i + 3, 'EM') { if has(s, i + 3, 'ER') || has(s, i + 3, 'EN') { choice(mut s, 'X', 'SK') } else { same(mut s, 'SK') } }
			else if i == 0 && !vowel(s, 3) && at(s, 3) != u8(`W`) { choice(mut s, 'X', 'S') }
			else { same(mut s, 'X') }
			return i + 3
		}
		if at(s, i + 2) == u8(`I`) || at(s, i + 2) == u8(`E`) || at(s, i + 2) == u8(`Y`) { same(mut s, 'S') } else { same(mut s, 'SK') }
		return i + 3
	}
	if i == s.length - 1 && (has(s, i - 2, 'AI') || has(s, i - 2, 'OI')) { choice(mut s, '', 'S') } else { same(mut s, 'S') }
	return i + if at(s, i + 1) == u8(`S`) || at(s, i + 1) == u8(`Z`) { 2 } else { 1 }
}

fn rule_t(mut s Encoder, i int) int {
	if has(s, i, 'TION') { same(mut s, 'X'); return i + 3 }
	if has(s, i, 'TIA') || has(s, i, 'TCH') { same(mut s, 'X'); return i + 3 }
	if has(s, i, 'TH') || has(s, i, 'TTH') { if has(s, i + 2, 'OM') || has(s, i + 2, 'AM') || has(s, 0, 'VAN ') || has(s, 0, 'VON ') || has(s, 0, 'SCH') { same(mut s, 'T') } else { choice(mut s, '0', 'T') }; return i + 2 }
	same(mut s, 'T')
	return i + if at(s, i + 1) == u8(`T`) || at(s, i + 1) == u8(`D`) { 2 } else { 1 }
}

fn rule_w(mut s Encoder, i int) int {
	if has(s, i, 'WR') { same(mut s, 'R'); return i + 2 }
	if i == 0 && (vowel(s, i + 1) || has(s, i, 'WH')) { if vowel(s, i + 1) { choice(mut s, 'A', 'F') } else { same(mut s, 'A') } }
	if (i == s.length - 1 && vowel(s, i - 1)) || has(s, i - 1, 'EWSKI') || has(s, i - 1, 'EWSKY') || has(s, i - 1, 'OWSKI') || has(s, i - 1, 'OWSKY') || has(s, 0, 'SCH') { choice(mut s, '', 'F'); return i + 1 }
	if has(s, i, 'WICZ') || has(s, i, 'WITZ') { choice(mut s, 'TS', 'FX'); return i + 4 }
	return i + 1
}

fn upper(value i64) u8 {
	if value >= 97 && value <= 122 { return u8(value - 32) }
	if value == 0xe7 { return 0xc7 }
	if value == 0xf1 { return 0xd1 }
	return u8(value)
}

@[export: 'double_metaphone']
pub fn double_metaphone(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 1 || length > 34 { return -1 }
	count_value := unsafe { values[0] }
	if count_value < 0 || count_value > 32 { return -1 }
	count := int(count_value)
	if length != usize(count + 1) { return -1 }
	mut s := Encoder{}
	for j in 0 .. text_limit + pad { s.text[j] = u8(` `) }
	s.length = count
	for j in 0 .. count {
		raw := unsafe { values[j + 1] }
		if !((raw >= 65 && raw <= 90) || (raw >= 97 && raw <= 122) || raw == 32 || raw == 0xc7 || raw == 0xe7 || raw == 0xd1 || raw == 0xf1) { return -1 }
		s.text[j] = upper(raw)
	}
	germanic := slavo(&s)
	mut i := 0
	if has(&s, 0, 'GN') || has(&s, 0, 'KN') || has(&s, 0, 'PN') || has(&s, 0, 'WR') || has(&s, 0, 'PS') { i = 1 }
	if at(&s, 0) == u8(`X`) { same(mut s, 'S'); i = 1 }
	for i < s.length && (s.primary_len < key_limit || s.secondary_len < key_limit) {
		match at(&s, i) {
		u8(`A`), u8(`E`), u8(`I`), u8(`O`), u8(`U`), u8(`Y`) { if i == 0 { same(mut s, 'A') }; i++ }
		u8(`B`) { same(mut s, 'P'); i += if at(&s, i + 1) == u8(`B`) { 2 } else { 1 } }
		0xc7 { same(mut s, 'S'); i++ }
		u8(`C`) { i = rule_c(mut s, i) }
		u8(`D`) {
			if has(&s, i, 'DG') { if at(&s, i + 2) == u8(`I`) || at(&s, i + 2) == u8(`E`) || at(&s, i + 2) == u8(`Y`) { same(mut s, 'J'); i += 3 } else { same(mut s, 'TK'); i += 2 } }
			else if has(&s, i, 'DT') || has(&s, i, 'DD') { same(mut s, 'T'); i += 2 } else { same(mut s, 'T'); i++ }
		}
		u8(`F`) { same(mut s, 'F'); i += if at(&s, i + 1) == u8(`F`) { 2 } else { 1 } }
		u8(`G`) { i = rule_g(mut s, i, germanic) }
		u8(`H`) { if (i == 0 || vowel(&s, i - 1)) && vowel(&s, i + 1) { same(mut s, 'H'); i += 2 } else { i++ } }
		u8(`J`) { i = rule_j(mut s, i, germanic) }
		u8(`K`) { same(mut s, 'K'); i += if at(&s, i + 1) == u8(`K`) { 2 } else { 1 } }
		u8(`L`) { i = rule_l(mut s, i) }
		u8(`M`) { if (has(&s, i - 1, 'UMB') && (i + 1 == s.length - 1 || has(&s, i + 2, 'ER'))) || at(&s, i + 1) == u8(`M`) { i += 2 } else { i++ }; same(mut s, 'M') }
		u8(`N`) { same(mut s, 'N'); i += if at(&s, i + 1) == u8(`N`) { 2 } else { 1 } }
		0xd1 { same(mut s, 'N'); i++ }
		u8(`P`) { if at(&s, i + 1) == u8(`H`) { same(mut s, 'F'); i += 2 } else { same(mut s, 'P'); i += if at(&s, i + 1) == u8(`P`) || at(&s, i + 1) == u8(`B`) { 2 } else { 1 } } }
		u8(`Q`) { same(mut s, 'K'); i += if at(&s, i + 1) == u8(`Q`) { 2 } else { 1 } }
		u8(`R`) { if i == s.length - 1 && !germanic && has(&s, i - 2, 'IE') && !has(&s, i - 4, 'ME') && !has(&s, i - 4, 'MA') { choice(mut s, '', 'R') } else { same(mut s, 'R') }; i += if at(&s, i + 1) == u8(`R`) { 2 } else { 1 } }
		u8(`S`) { i = rule_s(mut s, i, germanic) }
		u8(`T`) { i = rule_t(mut s, i) }
		u8(`V`) { same(mut s, 'F'); i += if at(&s, i + 1) == u8(`V`) { 2 } else { 1 } }
		u8(`W`) { i = rule_w(mut s, i) }
		u8(`X`) { french := i == s.length - 1 && (has(&s, i - 3, 'IAU') || has(&s, i - 3, 'EAU') || has(&s, i - 2, 'AU') || has(&s, i - 2, 'OU')); if !french { same(mut s, 'KS') }; i += if at(&s, i + 1) == u8(`C`) || at(&s, i + 1) == u8(`X`) { 2 } else { 1 } }
		u8(`Z`) { if at(&s, i + 1) == u8(`H`) { same(mut s, 'J'); i += 2 } else { if has(&s, i + 1, 'ZO') || has(&s, i + 1, 'ZI') || has(&s, i + 1, 'ZA') || (germanic && i > 0 && at(&s, i - 1) != u8(`T`)) { choice(mut s, 'S', 'TS') } else { same(mut s, 'S') }; i += if at(&s, i + 1) == u8(`Z`) { 2 } else { 1 } } }
		else { i++ }
		}
	}
	mut second_len := if s.alternate_seen { s.secondary_len } else { 0 }
	if second_len == s.primary_len && second_len == s.secondary_len {
		mut equal := true
		for j in 0 .. s.primary_len { if s.primary[j] != s.secondary[j] { equal = false } }
		if equal { second_len = 0 }
	}
	required := 2 + s.primary_len + second_len
	if unsafe { output == nil } || output_capacity < usize(required) { return -2 }
	unsafe {
		output[0] = u8(s.primary_len)
		output[1] = u8(second_len)
		for j in 0 .. s.primary_len { output[j + 2] = s.primary[j] }
		for j in 0 .. second_len { output[j + 2 + s.primary_len] = s.secondary[j] }
	}
	return i64(required)
}
