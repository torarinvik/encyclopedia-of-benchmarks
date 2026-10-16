"""Source-shaped reference oracle for the bounded Gauss Easter benchmark."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
import math

MIN_YEAR = 1
MAX_YEAR = 9999
INVALID_RESULT = -1


def expected_result(year: int) -> int:
    if type(year) is not int or not MIN_YEAR <= year <= MAX_YEAR:
        return INVALID_RESULT

    metonic_cycle = year % 19
    julian_leap_year = year % 4
    non_leap_year = year % 7
    leap_day_inhibits = math.floor(year / 100)
    lunar_orbit_correction = math.floor((13 + 8 * leap_day_inhibits) / 25)
    leap_day_reinstall_number = leap_day_inhibits / 4
    secular_moon_shift = (
        15 - lunar_orbit_correction + leap_day_inhibits - leap_day_reinstall_number
    ) % 30
    century_starting_point = (
        4 + leap_day_inhibits - leap_day_reinstall_number
    ) % 7
    days_to_add = (19 * metonic_cycle + secular_moon_shift) % 30
    days_from_phm_to_sunday = (
        2 * julian_leap_year
        + 4 * non_leap_year
        + 6 * days_to_add
        + century_starting_point
    ) % 7

    if days_to_add == 29 and days_from_phm_to_sunday == 6:
        result = datetime(year, 4, 19, tzinfo=timezone.utc)
    elif days_to_add == 28 and days_from_phm_to_sunday == 6:
        result = datetime(year, 4, 18, tzinfo=timezone.utc)
    else:
        result = datetime(year, 3, 22, tzinfo=timezone.utc) + timedelta(
            days=int(days_to_add + days_from_phm_to_sunday)
        )
    return year * 10_000 + result.month * 100 + result.day
