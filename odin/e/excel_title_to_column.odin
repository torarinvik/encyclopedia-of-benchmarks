package excel_title_to_column

import "core:c"

@(export)
excel_title_to_column :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > 13 do return -1
	count := values[0]
	if count < 1 || count > 12 || length != c.size_t(1 + count) do return -1

	column := i64(0)
	for index := i64(0); index < count; index += 1 {
		letter := values[1+index]
		if letter >= 97 && letter <= 122 {
			letter -= 32
		}
		if letter < 65 || letter > 90 do return -1
		column = column*26 + (letter - 65 + 1)
	}
	return column
}
