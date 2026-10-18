"""Oracle for deterministic seeded Java LotteryScheduling traces."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_PROCESSES = 16
MIN_PROCESS_ID = 0
MAX_PROCESS_ID = 32767
MIN_BURST_TIME = 1
MAX_BURST_TIME = 1000
MIN_TICKETS = 1
MAX_TICKETS = 1000
MAX_TOTAL_TICKETS = MAX_PROCESSES * MAX_TICKETS
MAX_TOTAL_BURST_TIME = MAX_PROCESSES * MAX_BURST_TIME
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_PROCESSES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 3 * MAX_PROCESSES
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_JAVA_RANDOM_MULTIPLIER = 0x5DEECE66D
_JAVA_RANDOM_ADDEND = 0xB
_JAVA_RANDOM_MASK = (1 << 48) - 1
_INT32_MAX = (1 << 31) - 1

SEMANTIC_CASE_IDS = frozenset({
    "zero_processes",
    "single_process",
    "seeded_equal_ticket_order",
    "weighted_tickets_and_waiting_times",
    "seed_uses_low_48_bits",
    "high_seed_bits_are_ignored",
    "next_int_rejection_sampling",
    "maximum_process_count",
})
ABI_CASE_IDS = frozenset({
    "null_input_positive_length",
    "empty_input",
    "truncated_process_records",
    "trailing_input_word",
    "negative_process_count",
    "process_count_above_bound",
    "duplicate_process_id",
    "negative_process_id",
    "process_id_above_bound",
    "negative_burst_time",
    "zero_burst_time",
    "burst_time_above_bound",
    "zero_ticket_count",
    "negative_ticket_count",
    "ticket_count_above_bound",
    "empty_output_capacity_zero",
    "null_output_zero_processes",
    "null_output_nonempty",
    "short_output_capacity",
    "exact_output_capacity",
    "max_output_capacity",
    "max_output_one_byte_short",
    "invalid_input_precedes_null_output",
})


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None

    seed, process_count = values[:2]
    if not 0 <= process_count <= MAX_PROCESSES:
        return None
    if len(values) != 2 + 3 * process_count:
        return None

    processes: list[tuple[int, int, int]] = []
    process_ids: set[int] = set()
    total_tickets = 0
    total_burst_time = 0
    for offset in range(2, len(values), 3):
        process_id, burst_time, tickets = values[offset:offset + 3]
        if not MIN_PROCESS_ID <= process_id <= MAX_PROCESS_ID:
            return None
        if process_id in process_ids:
            return None
        if not MIN_BURST_TIME <= burst_time <= MAX_BURST_TIME:
            return None
        if not MIN_TICKETS <= tickets <= MAX_TICKETS:
            return None
        process_ids.add(process_id)
        total_tickets += tickets
        total_burst_time += burst_time
        processes.append((process_id, burst_time, tickets))
    if total_tickets > MAX_TOTAL_TICKETS or total_burst_time > MAX_TOTAL_BURST_TIME:
        return None
    return seed, processes


def _next_java_random_state(state: int) -> int:
    """Advance java.util.Random's 48-bit LCG, preserving low 48 bits exactly."""
    low = state & 0xFFFFFF
    high = state >> 24
    low_product = low * _JAVA_RANDOM_MULTIPLIER
    high_product = (high * _JAVA_RANDOM_MULTIPLIER) & 0xFFFFFF
    return (low_product + (high_product << 24) + _JAVA_RANDOM_ADDEND) & _JAVA_RANDOM_MASK


def _java_next_int(state: int, bound: int) -> tuple[int, int]:
    """Return Java Random.nextInt(bound) and its updated internal state."""
    if bound <= 0:
        raise ValueError("bound must be positive")
    if bound & (bound - 1) == 0:
        state = _next_java_random_state(state)
        bits = state >> 17
        return (bound * bits) >> 31, state

    while True:
        state = _next_java_random_state(state)
        bits = state >> 17
        value = bits % bound
        # Java evaluates this rejection condition with signed 32-bit overflow.
        if bits - value + (bound - 1) <= _INT32_MAX:
            return value, state


def _simulate(values: Sequence[int] | None) -> bytes | None:
    parsed = _parse(values)
    if parsed is None:
        return None
    seed, pending = parsed
    state = (seed ^ _JAVA_RANDOM_MULTIPLIER) & _JAVA_RANDOM_MASK
    current_time = 0
    results: list[int] = []

    while pending:
        total_tickets = sum(process[2] for process in pending)
        random_value, state = _java_next_int(state, total_tickets)
        winning_ticket = random_value + 1
        cumulative_tickets = 0
        selected_index = -1
        for index, (_, _, tickets) in enumerate(pending):
            cumulative_tickets += tickets
            if cumulative_tickets >= winning_ticket:
                selected_index = index
                break
        if selected_index < 0:
            return None

        process_id, burst_time, _ = pending.pop(selected_index)
        waiting_time = current_time
        turnaround_time = waiting_time + burst_time
        results.extend((process_id, waiting_time, turnaround_time))
        current_time += burst_time

    output = struct.pack("<" + "q" * len(results), *results) if results else b""
    if len(output) > MAX_OUTPUT_BYTES:
        return None
    return output


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return scheduled process records or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    output = _simulate(values)
    if output is None:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
