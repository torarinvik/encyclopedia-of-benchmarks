"""Oracle for the Java and JavaScript LRU cache operation-trace contract."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_CAPACITY = 2
MAX_CAPACITY = 16
MAX_OPERATION_COUNT = 32
MIN_KEY = 0
MAX_KEY = 1_000_000
MIN_VALUE = 0
MAX_VALUE = 1_000_000
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_OPERATION_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 + 3 * MAX_OPERATION_COUNT + 2 * MAX_CAPACITY
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

SEMANTIC_CASE_IDS = frozenset({
    "empty_trace",
    "put_then_get",
    "hit_refresh_then_evict_lru",
    "multiple_evictions_and_reaccess",
    "capacity_two_recency_boundary",
    "non_power_of_two_capacity",
    "maximum_capacity_trace",
    "maximum_operation_trace",
})
ABI_CASE_IDS = frozenset({
    "null_input_positive_length",
    "empty_input",
    "truncated_operation",
    "trailing_input_word",
    "capacity_below_minimum",
    "capacity_above_maximum",
    "negative_operation_count",
    "operation_count_above_maximum",
    "invalid_opcode",
    "negative_key",
    "key_above_maximum",
    "negative_put_value",
    "put_value_above_maximum",
    "get_value_field_must_be_zero",
    "get_missing_key",
    "get_evicted_key",
    "duplicate_put_key",
    "null_output_empty_trace",
    "null_output_nonempty_trace",
    "short_output_capacity",
    "exact_output_capacity",
    "maximum_output_one_byte_short",
    "invalid_input_precedes_output_error",
})


def _simulate(values: Sequence[int] | None) -> bytes | None:
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None

    capacity, operation_count = values[:2]
    if not MIN_CAPACITY <= capacity <= MAX_CAPACITY:
        return None
    if not 0 <= operation_count <= MAX_OPERATION_COUNT:
        return None
    if len(values) != 2 + 3 * operation_count:
        return None

    # `order` stores least-recently-used first; `cache` retains the associated values.
    cache: dict[int, int] = {}
    order: list[int] = []
    seen_put_keys: set[int] = set()
    records: list[int] = []
    cursor = 2

    for _ in range(operation_count):
        opcode, key, value = values[cursor:cursor + 3]
        cursor += 3
        if not MIN_KEY <= key <= MAX_KEY:
            return None

        if opcode == 0:  # Java put / JavaScript set
            if (not MIN_VALUE <= value <= MAX_VALUE
                    or key in seen_put_keys):
                return None
            seen_put_keys.add(key)
            evicted = -1
            if len(order) == capacity:
                evicted = order.pop(0)
                del cache[evicted]
            cache[key] = value
            order.append(key)
            records.extend((opcode, -1, evicted))
        elif opcode == 1:  # get; misses are outside the common source domain
            if value != 0 or key not in cache:
                return None
            cached_value = cache[key]
            order.remove(key)
            order.append(key)
            records.extend((opcode, cached_value, -1))
        else:
            return None

    fields = [operation_count, *records, len(order)]
    for key in reversed(order):
        fields.extend((key, cache[key]))
    output = b"".join(struct.pack("<q", field) for field in fields)
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
    """Return the trace records or the documented ABI error."""
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
