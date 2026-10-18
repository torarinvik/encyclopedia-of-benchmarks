"""Oracle for the bounded C# Timeline<TValue> operation trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_INITIAL_EVENTS = 0
MAX_INITIAL_EVENTS = 16
MIN_COMMANDS = 0
MAX_COMMANDS = 32
MAX_EVENTS = MAX_INITIAL_EVENTS + MAX_COMMANDS
MIN_TICKS = 0
MAX_TICKS = 1_000_000
MIN_VALUE = -32
MAX_VALUE = 32
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_INITIAL_EVENTS + 3 * MAX_COMMANDS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
# The maximum trace uses 16 initial events, 9 appends, and 23 full-value
# queries: 691 words including command headers and the final event snapshot.
MAX_OUTPUT_WORDS = 691
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_WORDS
INVALID_RESULT = -1
OUTPUT_ERROR = -2

COMMAND_IDS = frozenset({
    "empty_timeline",
    "constructor_stable_sort_duplicates",
    "add_appends_without_resorting",
    "queries_exact_and_before_after",
    "remove_first_matching_pair",
    "remove_all_at_time",
    "remove_all_by_value",
    "contains_time_and_value",
    "clear_then_query",
    "maximum_input_shape",
})
ABI_CASE_IDS = frozenset({
    "null_input_positive_length",
    "empty_input",
    "truncated_initial_pairs",
    "truncated_command",
    "trailing_input_word",
    "opcode_out_of_range",
    "initial_count_above_bound",
    "command_count_above_bound",
    "timestamp_out_of_range",
    "value_out_of_range",
    "unused_operand_nonzero",
    "null_output_empty",
    "null_output_nonempty",
    "short_output_capacity",
    "exact_output_capacity",
    "max_output_capacity",
    "max_output_one_byte_short",
})


def _decode_input(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None

    initial_count = values[0]
    if not MIN_INITIAL_EVENTS <= initial_count <= MAX_INITIAL_EVENTS:
        return None
    command_count_index = 1 + 2 * initial_count
    if command_count_index >= len(values):
        return None
    command_count = values[command_count_index]
    if not MIN_COMMANDS <= command_count <= MAX_COMMANDS:
        return None
    if len(values) != 2 + 2 * initial_count + 3 * command_count:
        return None

    initial_events: list[tuple[int, int]] = []
    offset = 1
    for _ in range(initial_count):
        ticks, value = values[offset:offset + 2]
        if not MIN_TICKS <= ticks <= MAX_TICKS or not MIN_VALUE <= value <= MAX_VALUE:
            return None
        initial_events.append((ticks, value))
        offset += 2
    offset += 1  # command count

    commands: list[tuple[int, int, int]] = []
    for _ in range(command_count):
        opcode, first, second = values[offset:offset + 3]
        if not 0 <= opcode <= 14:
            return None
        if opcode in (0, 1, 2):  # Add, Contains, Remove
            if not MIN_TICKS <= first <= MAX_TICKS or not MIN_VALUE <= second <= MAX_VALUE:
                return None
        elif opcode in (3, 4, 5, 6, 8):  # time argument
            if not MIN_TICKS <= first <= MAX_TICKS or second != 0:
                return None
        elif opcode in (7, 9):  # value argument
            if not MIN_VALUE <= first <= MAX_VALUE or second != 0:
                return None
        elif first != 0 or second != 0:  # zero-argument command
            return None
        commands.append((opcode, first, second))
        offset += 3
    return initial_events, commands


def _unique_times(events: Sequence[tuple[int, int]]) -> list[int]:
    return list(dict.fromkeys(ticks for ticks, _ in events))


def _run(initial_events: list[tuple[int, int]], commands: list[tuple[int, int, int]]) -> list[int]:
    # The pinned constructor uses stable OrderBy; later Add calls simply append.
    events = sorted(initial_events, key=lambda event: event[0])
    words: list[int] = []
    for opcode, first, second in commands:
        payload: list[int]
        if opcode == 0:  # Add(time, value)
            events.append((first, second))
            payload = []
        elif opcode == 1:  # Contains(time, value)
            payload = [int((first, second) in events)]
        elif opcode == 2:  # Remove(time, value), first matching event only
            try:
                events.remove((first, second))
                payload = [1]
            except ValueError:
                payload = [0]
        elif opcode == 3:  # GetValuesByTime(time), in current list order
            payload = [value for ticks, value in events if ticks == first]
        elif opcode == 4:  # GetTimesBefore(time), distinct and sorted
            payload = sorted(ticks for ticks in _unique_times(events) if ticks < first)
        elif opcode == 5:  # GetTimesAfter(time), distinct and sorted
            payload = sorted(ticks for ticks in _unique_times(events) if ticks > first)
        elif opcode == 6:  # RemoveTimes(time), removes every matching event
            existed = any(ticks == first for ticks, _ in events)
            if existed:
                events = [(ticks, value) for ticks, value in events if ticks != first]
            payload = [int(existed)]
        elif opcode == 7:  # RemoveValues(value), removes every matching event
            existed = any(value == first for _, value in events)
            if existed:
                events = [(ticks, value) for ticks, value in events if value != first]
            payload = [int(existed)]
        elif opcode == 8:  # ContainsTime(time)
            payload = [int(any(ticks == first for ticks, _ in events))]
        elif opcode == 9:  # ContainsValue(value)
            payload = [int(any(value == first for _, value in events))]
        elif opcode == 10:  # GetAllTimes(), distinct in first-seen order
            payload = _unique_times(events)
        elif opcode == 11:  # GetAllValues(), current list order
            payload = [value for _, value in events]
        elif opcode == 12:  # TimesCount
            payload = [len(_unique_times(events))]
        elif opcode == 13:  # ValuesCount / Count
            payload = [len(events)]
        else:  # Clear
            events.clear()
            payload = []

        words.extend((opcode, len(payload)))
        words.extend(payload)

    words.extend((-1, len(events)))
    for ticks, value in events:
        words.extend((ticks, value))
    return words


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the command-result trace and final event list, or ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, b""
    initial_events, commands = decoded
    words = _run(initial_events, commands)
    output = b"".join(struct.pack("<q", word) for word in words)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
