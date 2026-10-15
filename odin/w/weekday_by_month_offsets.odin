package weekday_by_month_offsets

import "core:c"

is_leap_year :: proc(year: i64) -> bool {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

month_offset :: proc(month: i64) -> i64 {
    switch month {
    case 1: return 0
    case 2: return 3
    case 3: return 2
    case 4: return 5
    case 5: return 0
    case 6: return 3
    case 7: return 5
    case 8: return 1
    case 9: return 4
    case 10: return 6
    case 11: return 2
    case 12: return 4
    }
    return -1
}

@(export)
weekday_by_month_offsets :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 3 do return -1
    year, month, day := values[0], values[1], values[2]
    if year < 100 || year > 9999 || month < 1 || month > 12 do return -1
    leap := is_leap_year(year)
    days_in_month := i64(31)
    if month == 2 {
        days_in_month = if leap do 29 else 28
    } else if month == 4 || month == 6 || month == 9 || month == 11 {
        days_in_month = 30
    }
    if day < 1 || day > days_in_month do return -1

    adjusted_year := year
    if month < 3 do adjusted_year -= 1
    return (adjusted_year + adjusted_year / 4 - adjusted_year / 100
        + adjusted_year / 400 + month_offset(month) + day) % 7
}
