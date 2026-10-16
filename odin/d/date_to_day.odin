package date_to_day

import "core:c"

// Return the English weekday name for a bounded ASCII d/m/yyyy date.
@(export)
date_to_day :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 9 || length > 11 || input[length - 1] != 0 do return -1
    date_length := length - 1
    cursor := c.size_t(0)
    fields: [3]int
    for field in 0..<3 {
        start := cursor
        value := 0
        for cursor < date_length && input[cursor] >= 48 && input[cursor] <= 57 {
            value = value * 10 + int(input[cursor] - 48)
            cursor += 1
        }
        digits := cursor - start
        max_digits := c.size_t(2)
        if field == 2 do max_digits = 4
        if digits == 0 || digits > max_digits || (field == 2 && digits != 4) do return -1
        fields[field] = value
        if field < 2 {
            if cursor >= date_length || input[cursor] != 47 do return -1
            cursor += 1
        }
    }
    if cursor != date_length do return -1
    day, month, year := fields[0], fields[1], fields[2]
    if year < 1 || year > 9999 || month < 1 || month > 12 || day < 1 do return -1
    leap := year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)
    month_days := [12]int{31,28,31,30,31,30,31,31,30,31,30,31}
    if leap do month_days[1] = 29
    if day > month_days[month - 1] do return -1

    adjusted_year, adjusted_month := year, month
    if adjusted_month < 3 { adjusted_year -= 1; adjusted_month += 12 }
    year_of_century := adjusted_year % 100
    century := adjusted_year / 100
    weekday := (day + ((adjusted_month + 1) * 26) / 10 + year_of_century +
        year_of_century / 4 + century / 4 + 5 * century) % 7
    names := [7]string{"Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"}
    name := names[weekday]
    if output_capacity < c.size_t(len(name)) || output == nil do return -2
    for index := 0; index < len(name); index += 1 { output[index] = u8(name[index]) }
    return i64(len(name))
}
