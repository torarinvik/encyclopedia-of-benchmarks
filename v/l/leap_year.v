module leap_year

// Return 1 for a positive Gregorian leap year, 0 otherwise, or -1 for invalid years.
@[export: 'leap_year']
pub fn leap_year(year i64) i64 {
	if year <= 0 {
		return -1
	}
	if year % 400 == 0 || (year % 4 == 0 && year % 100 != 0) {
		return 1
	}
	return 0
}
