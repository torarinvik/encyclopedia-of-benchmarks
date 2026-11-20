from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn is_leap_year(year: Int64) -> Bool:
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

fn decode_offset(offset: Int64) -> (Int64, Int64):
    let shifted = offset + 719468
    let era = shifted // 146097
    let day_of_era = shifted - era * 146097
    let year_of_era = (day_of_era - day_of_era // 1460 + day_of_era // 36524
        - day_of_era // 146096) // 365
    var year = year_of_era + era * 400
    let day_of_year_march = day_of_era - (
        365 * year_of_era + year_of_era // 4 - year_of_era // 100
    )
    let month_march = (5 * day_of_year_march + 2) // 153
    let day = day_of_year_march - (153 * month_march + 2) // 5 + 1
    let month = month_march + (3 if month_march < 10 else -9)
    if month <= 2:
        year += 1
    let days_before_month = InlineArray[Int64, 12](
        0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334
    )
    let leap_adjustment = 1 if month > 2 and is_leap_year(year) else 0
    return (year, days_before_month[Int(month - 1)] + leap_adjustment + day)

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
                value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("gregorian_daycount_to_ordinal_date")
fn gregorian_daycount_to_ordinal_date(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 2 or length != 1:
        return -1
    let offset = input[0]
    if offset < -146097 or offset > 146097:
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16:
        return -2
    let (year, ordinal) = decode_offset(offset)
    store_i64_le(output, 0, year)
    store_i64_le(output, 8, ordinal)
    return 16
