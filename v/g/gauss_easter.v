module gauss_easter

@[export: 'gauss_easter']
pub fn gauss_easter(year i64) i64 {
	if year < 1 || year > 9999 { return -1 }
	a := year % 19
	b := year % 4
	c := year % 7
	century := year / 100
	lunar_correction := (13 + 8 * century) / 25
	moon_q := (60 - 4 * lunar_correction + 3 * century) % 120
	start_q := (16 + 3 * century) % 28
	add_q := (76 * a + moon_q) % 120
	sunday_q := (8 * b + 16 * c + start_q + 6 * add_q) % 28
	mut month := i64(0)
	mut day := i64(0)
	if add_q == 116 && sunday_q == 24 {
		month = 4
		day = 19
	} else if add_q == 112 && sunday_q == 24 {
		month = 4
		day = 18
	} else {
		march_day := 22 + (add_q + sunday_q) / 4
		if march_day <= 31 {
			month = 3
			day = march_day
		} else {
			month = 4
			day = march_day - 31
		}
	}
	return year * 10000 + month * 100 + day
}
