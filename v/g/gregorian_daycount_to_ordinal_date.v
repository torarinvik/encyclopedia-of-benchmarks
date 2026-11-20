module gregorian_daycount_to_ordinal_date

fn is_leap_year(year i64) bool {
	return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

fn decode_offset(offset i64) (i64, i64) {
	shifted := offset + 719468
	era := shifted / 146097
	day_of_era := shifted - era * 146097
	year_of_era := (day_of_era - day_of_era / 1460 + day_of_era / 36524 - day_of_era / 146096) / 365
	mut year := year_of_era + era * 400
	day_of_year_march := day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100)
	month_march := (5 * day_of_year_march + 2) / 153
	day := day_of_year_march - (153 * month_march + 2) / 5 + 1
	month := month_march + if month_march < 10 { 3 } else { -9 }
	if month <= 2 { year++ }
	days_before_month := [12]i64{0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334}
	leap_adjustment := i64(0)
	if month > 2 && is_leap_year(year) { leap_adjustment = 1 }
	return year, days_before_month[int(month - 1)] + leap_adjustment + day
}

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits >> (8 * byte)) }
	}
}

@[export: 'gregorian_daycount_to_ordinal_date']
pub fn gregorian_daycount_to_ordinal_date(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 2 || length != 1 { return -1 }
	offset := unsafe { input[0] }
	if offset < -146097 || offset > 146097 { return -1 }
	if unsafe { output == nil } || capacity < 16 { return -2 }
	year, ordinal := decode_offset(offset)
	store_i64_le(output, 0, year)
	store_i64_le(output, 8, ordinal)
	return 16
}
