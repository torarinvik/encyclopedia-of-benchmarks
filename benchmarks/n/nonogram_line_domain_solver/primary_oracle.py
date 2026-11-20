"""Primary line-domain reference for the bounded nonogram contract."""

from __future__ import annotations

from typing import Optional, Sequence

MAX_SIDE = 8
MAX_RUNS = 4
LINE_COUNT = 16
MASK_WORDS = 4
MAX_VALID_INPUT_LENGTH = 82
MAX_INPUT_LENGTH = 83
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 64


def _parse(values: list[int]) -> Optional[tuple[int, int, list[list[int]], list[list[int]]]]:
    if len(values) < 2:
        return None
    height, width = values[0], values[1]
    if not (1 <= height <= MAX_SIDE and 1 <= width <= MAX_SIDE):
        return None
    if len(values) != 2 + 5 * height + 5 * width:
        return None
    offset = 2
    groups: list[list[list[int]]] = []
    for line_count, line_length in ((height, width), (width, height)):
        clues: list[list[int]] = []
        for _ in range(line_count):
            run_count = values[offset]
            offset += 1
            if not (0 <= run_count <= MAX_RUNS):
                return None
            runs = values[offset:offset + MAX_RUNS]
            offset += MAX_RUNS
            if any(run <= 0 for run in runs[:run_count]):
                return None
            if any(run != 0 for run in runs[run_count:]):
                return None
            if sum(runs[:run_count]) + max(0, run_count - 1) > line_length:
                return None
            clues.append(runs[:run_count])
        groups.append(clues)
    rows, columns = groups
    if sum(map(sum, rows)) != sum(map(sum, columns)):
        return None
    return height, width, rows, columns


def _runs(mask: int, length: int) -> list[int]:
    found: list[int] = []
    run = 0
    for bit in range(length):
        if mask & (1 << bit):
            run += 1
        elif run:
            found.append(run)
            run = 0
    if run:
        found.append(run)
    return found


def _line_domain(length: int, clue: list[int]) -> set[int]:
    return {mask for mask in range(1 << length) if _runs(mask, length) == clue}


def _has(domain: list[int], mask: int) -> bool:
    return bool(domain[mask >> 6] & (1 << (mask & 63)))


def _set(domain: list[int], mask: int) -> None:
    domain[mask >> 6] |= 1 << (mask & 63)


def _masks(domain: list[int], length: int):
    for mask in range(1 << length):
        if _has(domain, mask):
            yield mask


def _filter(domain: list[int], length: int, position: int,
            allow_zero: bool, allow_one: bool) -> bool:
    changed = False
    for mask in range(1 << length):
        if _has(domain, mask) and not (allow_one if mask & (1 << position) else allow_zero):
            domain[mask >> 6] &= ~(1 << (mask & 63))
            changed = True
    return changed


def _count(domain: list[int], length: int) -> int:
    return sum(1 for _ in _masks(domain, length))


def _propagate(domains: list[list[int]], height: int, width: int) -> bool:
    changed = True
    while changed:
        changed = False
        for row in range(height):
            for column in range(width):
                col_domain = domains[height + column]
                row_domain = domains[row]
                row_one = any(mask & (1 << column) for mask in _masks(row_domain, width))
                row_zero = any(not mask & (1 << column) for mask in _masks(row_domain, width))
                col_one = any(mask & (1 << row) for mask in _masks(col_domain, height))
                col_zero = any(not mask & (1 << row) for mask in _masks(col_domain, height))
                if not row_one and not row_zero or not col_one and not col_zero:
                    return False
                changed |= _filter(row_domain, width, column, col_zero, col_one)
                changed |= _filter(col_domain, height, row, row_zero, row_one)
                if _count(row_domain, width) == 0 or _count(col_domain, height) == 0:
                    return False
    return True


def _search(domains: list[list[int]], height: int, width: int) -> bool:
    if not _propagate(domains, height, width):
        return False
    branch = -1
    for row in range(height):
        if _count(domains[row], width) > 1:
            branch = row
            break
    if branch < 0:
        return True
    for mask in list(_masks(domains[branch], width)):
        trial = [line.copy() for line in domains]
        trial[branch] = [0, 0, 0, 0]
        _set(trial[branch], mask)
        if _search(trial, height, width):
            domains[:] = trial
            return True
    return False


def solve(values: list[int]) -> Optional[bytes]:
    parsed = _parse(values)
    if parsed is None:
        return None
    height, width, row_clues, column_clues = parsed
    domains = [[0, 0, 0, 0] for _ in range(LINE_COUNT)]
    for row, clue in enumerate(row_clues):
        for mask in _line_domain(width, clue):
            _set(domains[row], mask)
    for column, clue in enumerate(column_clues):
        for mask in _line_domain(height, clue):
            _set(domains[height + column], mask)
    if any(_count(domains[line], width) == 0 for line in range(height)):
        return None
    if any(_count(domains[height + column], height) == 0 for column in range(width)):
        return None
    if not _search(domains, height, width):
        return None
    output = bytearray()
    for row in range(height):
        mask = next(_masks(domains[row], width))
        output.extend((mask >> column) & 1 for column in range(width))
    return bytes(output)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or input_length < 0)
            or input_is_null and (values not in (None, [], ())
                                  or input_length not in (None, 0))
            or not input_is_null and values is not None
            and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    parsed = _parse(list(values))
    if parsed is None:
        return -1, b""
    result = solve(list(values))
    if result is None:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result


def expected_call(values: list[int], capacity: Optional[int] = None) -> tuple[int, bytes]:
    return expected_output(values, capacity)

