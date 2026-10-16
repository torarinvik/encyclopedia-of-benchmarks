"""Bounded source-faithful oracle for the Rust depreciation schedules."""

from __future__ import annotations

import math
import struct

MAX_YEARS = 16
MAX_VALUE_MICRO = 1_000_000_000_000
MAX_RATE_PPM = 1_000_000
MAX_UNITS = 1_000_000_000
MAX_INPUT_LENGTH = MAX_YEARS + 4
SCALE = 1_000_000.0


def expected_output(values: list[int] | tuple[int, ...],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return one schedule as little-endian binary64 bytes, or an error."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    method = values[0]
    if method in (0, 3, 4):
        if len(values) != 4:
            return -1, b""
        years, purchase_scaled, residual_scaled = values[1:]
        rate = None
        units = None
    elif method == 1:
        if len(values) != 5:
            return -1, b""
        years, purchase_scaled, residual_scaled, rate_scaled = values[1:]
        rate = rate_scaled / SCALE
        units = None
        if not 1 <= rate_scaled <= MAX_RATE_PPM:
            return -1, b""
    elif method == 2:
        if len(values) < 5:
            return -1, b""
        purchase_scaled, residual_scaled, total_units, *units = values[1:]
        years = len(units)
        rate = None
        if not 1 <= total_units <= MAX_UNITS or any(abs(unit) > MAX_UNITS for unit in units):
            return -1, b""
        units_sum = sum(units)
        if abs(units_sum - total_units) > 1.0e-6 * total_units:
            return -1, b""
    else:
        return -1, b""

    if (not 1 <= years <= MAX_YEARS
            or not 0 <= purchase_scaled <= MAX_VALUE_MICRO
            or not -MAX_VALUE_MICRO <= residual_scaled <= purchase_scaled):
        return -1, b""
    purchase = purchase_scaled / SCALE
    residual = residual_scaled / SCALE
    depreciable_cost = purchase - residual

    if method == 0:
        annual = depreciable_cost / years
        schedule: list[float] = []
        accumulated = 0.0
        for period in range(years):
            if period == years - 1:
                schedule.append(depreciable_cost - accumulated)
            else:
                accumulated += annual
                schedule.append(annual)
    elif method == 1:
        assert rate is not None
        schedule = []
        book_value = purchase
        for period in range(years):
            if period == years - 1:
                schedule.append(book_value - residual)
            else:
                expense = min(book_value * rate, book_value - residual)
                schedule.append(expense)
                book_value -= expense
    elif method == 2:
        assert units is not None
        per_unit = depreciable_cost / total_units
        schedule = []
        accumulated = 0.0
        for index, units_in_period in enumerate(units):
            if index == years - 1:
                schedule.append(depreciable_cost - accumulated)
            else:
                expense = units_in_period * per_unit
                accumulated += expense
                schedule.append(expense)
    elif method == 3:
        syd = years * (years + 1.0) / 2.0
        schedule = []
        accumulated = 0.0
        for period in range(1, years + 1):
            if period == years:
                schedule.append(depreciable_cost - accumulated)
            else:
                expense = ((years - period + 1.0) / syd) * depreciable_cost
                accumulated += expense
                schedule.append(expense)
    else:
        rate = 2.0 / years
        schedule = []
        book_value = purchase
        accumulated = 0.0
        for period in range(1, years + 1):
            remaining_years = years - period + 1.0
            ddb_expense = max(book_value * rate, 0.0)
            sl_expense = max((book_value - residual) / remaining_years, 0.0)
            expense = min(max(ddb_expense, sl_expense), book_value - residual)
            if period == years:
                schedule.append(depreciable_cost - accumulated)
            else:
                accumulated += expense
                schedule.append(expense)
                book_value -= expense

    if not all(math.isfinite(value) for value in schedule):
        return -1, b""
    output = struct.pack("<" + "d" * years, *schedule)
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return -1, b""
        if len(output) > capacity:
            return -2, b""
    return len(output), output
