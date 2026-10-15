package julian_easter

// Meeus Julian Easter date encoded as YYYYMMDD.
@(export)
julian_easter :: proc "c" (year: i64) -> i64 {
	if year < 1 || year > 9999 do return -1
	a := year % 4
	b := year % 7
	c := year % 19
	d := (19 * c + 15) % 30
	e := (2 * a + 4 * b - d + 34) % 7
	day_of_year := d + e + 114
	month := day_of_year / 31
	day := day_of_year % 31 + 1
	return year * 10000 + month * 100 + day
}
