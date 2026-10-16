package gauss_easter

@(export)
gauss_easter :: proc "c" (year: i64) -> i64 {
	if year < 1 || year > 9999 do return -1
	a := year % 19
	b := year % 4
	c := year % 7
	century := year / 100
	lunar_correction := (13 + 8 * century) / 25
	moon_q := (60 - 4 * lunar_correction + 3 * century) % 120
	start_q := (16 + 3 * century) % 28
	add_q := (76 * a + moon_q) % 120
	sunday_q := (8 * b + 16 * c + start_q + 6 * add_q) % 28
	month, day: i64
	if add_q == 116 && sunday_q == 24 {
		month, day = 4, 19
	} else if add_q == 112 && sunday_q == 24 {
		month, day = 4, 18
	} else {
		march_day := 22 + (add_q + sunday_q) / 4
		if march_day <= 31 {
			month, day = 3, march_day
		} else {
			month, day = 4, march_day - 31
		}
	}
	return year * 10000 + month * 100 + day
}
