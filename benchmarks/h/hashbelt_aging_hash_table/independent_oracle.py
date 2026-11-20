"""Map-per-generation reference for a bounded rotating hashbelt."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS + 1
MAX_OUTPUT_BYTES = MAX_OPERATIONS * 8
WORKSPACE_BYTES = 4096
MISS = -(1 << 31)


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    for value in values:
        if type(value) is not int or value < -(1 << 63) or value >= (1 << 63):
            return None
    count = values[0]
    if count < 0 or count > MAX_OPERATIONS or len(values) != 1 + 3 * count:
        return None
    records = []
    for position in range(1, len(values), 3):
        opcode, key, argument = values[position:position + 3]
        if opcode == 0 and 0 <= key <= 31 and -1000 <= argument <= 1000:
            records.append(("put", key, argument))
        elif opcode == 1 and 0 <= key <= 31 and argument == 0:
            records.append(("get", key, 0))
        elif opcode == 2 and key == 0 and argument == 0:
            records.append(("age", 0, 0))
        else:
            return None
    return records


def _run_generation_maps(records: list[tuple[str, int, int]]) -> list[int]:
    generations: list[dict[int, int]] = [{}, {}, {}, {}]
    trace: list[int] = []
    for action, key, argument in records:
        if action == "put":
            old_generation = next((index for index, generation in enumerate(generations)
                                   if key in generation), -1)
            previously_present = old_generation >= 0
            if old_generation > 0:
                del generations[old_generation][key]
            generations[0][key] = argument
            trace.append(0 if previously_present else 1)
        elif action == "get":
            found = None
            found_generation = -1
            for generation_index, generation in enumerate(generations):
                if key in generation:
                    found = generation[key]
                    found_generation = generation_index
                    break
            if found is None:
                trace.append(MISS)
            else:
                trace.append(found)
                if found_generation > 0:
                    del generations[found_generation][key]
                generations[0][key] = found
        else:
            trace.append(len(generations[-1]))
            generations = [{}, generations[0], generations[1], generations[2]]
    return trace


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    records = _decode(values)
    if records is None:
        return -1, b""
    result = b"".join(value.to_bytes(8, "little", signed=True)
                      for value in _run_generation_maps(records))
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result
