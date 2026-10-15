package easter

// Gregorian Easter date, packed as month * 100 + day.
@(export)
easter :: proc "c" (year: i64) -> i64 {
	if year < 0 || year > 9999 {
		return -1
	}
	if year <= 1582 {
		return 0
	}
	a := year % 19
	b := year / 100
	c := year % 100
	d := b / 4
	e := b % 4
	f := (b + 8) / 25
	g := (b - f + 1) / 3
	h := (19 * a + b - d - g + 15) % 30
	i := c / 4
	k := c % 4
	r := (32 + 2 * e + 2 * i - h - k) % 7
	m := (a + 11 * h + 22 * r) / 451
	date := h + r - 7 * m + 114
	month := date / 31
	day := date % 31 + 1
	return month * 100 + day
}
