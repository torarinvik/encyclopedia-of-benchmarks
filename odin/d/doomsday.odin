package doomsday

import "core:c"

is_leap_year :: proc(year: i64) -> bool {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
}

month_anchor :: proc(month: i64, leap: bool) -> i64 {
    switch month {
    case 1:
        if leap do return 4
        return 3
    case 2:
        if leap do return 1
        return 7
    case 3: return 7
    case 4: return 4
    case 5: return 2
    case 6: return 6
    case 7: return 4
    case 8: return 1
    case 9: return 5
    case 10: return 3
    case 11: return 7
    case 12: return 5
    }
    return -1
}

@(export)
doomsday :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
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

    within_century := year % 100
    century_anchor := (5 * ((year / 100) % 4) + 2) % 7
    doom := (within_century / 12 + within_century % 12
        + (within_century % 12) / 4 + century_anchor) % 7
    weekday := (doom + day - month_anchor(month, leap)) % 7
    if weekday < 0 do weekday += 7
    return weekday
}
