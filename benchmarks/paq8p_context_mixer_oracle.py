"""Independent model of the reduced PAQ8p neural context-mixer profile."""
from collections.abc import Sequence
import struct

MAX_STEPS = 16
WORDS_PER_STEP = 11
MAX_INPUT_LENGTH = 1 + MAX_STEPS * WORDS_PER_STEP
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 2 * MAX_STEPS
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_SQUASH_TABLE = (1, 2, 3, 6, 10, 16, 27, 45, 73, 120, 194, 310, 488, 747,
                 1101, 1546, 2047, 2549, 2994, 3348, 3607, 3785, 3901,
                 3975, 4022, 4050, 4068, 4079, 4085, 4089, 4092, 4093, 4094)


def _squash(value: int) -> int:
    if value > 2047:
        return 4095
    if value < -2047:
        return 0
    weight = value & 127
    index = (value >> 7) + 16
    return (_SQUASH_TABLE[index] * (128 - weight)
            + _SQUASH_TABLE[index + 1] * weight + 64) >> 7


def _stretch_table() -> list[int]:
    table = [0] * 4096
    next_index = 0
    for value in range(-2047, 2048):
        probability = _squash(value)
        for index in range(next_index, probability + 1):
            table[index] = value
        next_index = probability + 1
    table[4095] = 2047
    return table


_STRETCH = _stretch_table()


def _dot(inputs: list[int], weights: list[int]) -> int:
    total = 0
    for i in range(0, 8, 2):
        total += (inputs[i] * weights[i] + inputs[i + 1] * weights[i + 1]) >> 8
    return total


def _train(inputs: list[int], weights: list[int], error: int) -> None:
    for i in range(8):
        change = ((inputs[i] * error * 2 >> 16) + 1) >> 1
        weights[i] = min(32767, max(-32768, weights[i] + change))


def _simulate(steps: list[tuple[int, int, int, list[int]]]) -> bytes:
    # Outer Mixer(8,4,2,0), with its source-created Mixer(2,1,1,0x7fff).
    outer_weights = [[0] * 8 for _ in range(4)]
    inner_weights = [32767] * 8
    previous_inner: list[int] | None = None
    previous_inner_prediction = 2048
    previous_target = 0
    output = bytearray()

    for step_index, (cx0, cx1, target, inputs) in enumerate(steps):
        if step_index:
            err = ((previous_target << 12) - previous_inner_prediction) * 7
            _train(previous_inner or [0] * 8, inner_weights, err)

        contexts = (cx0, 2 + cx1)
        expert_predictions = []
        for context in contexts:
            expert_predictions.append(_squash(_dot(inputs, outer_weights[context]) >> 5))
        inner_inputs = [_STRETCH[expert_predictions[0]], _STRETCH[expert_predictions[1]]] + [0] * 6
        prediction = _squash(_dot(inner_inputs, inner_weights) >> 8)
        output.extend(struct.pack("<H", prediction))

        for context, model_prediction in zip(contexts, expert_predictions):
            error = ((target << 12) - model_prediction) * 7
            _train(inputs, outer_weights[context], error)
        previous_inner = inner_inputs
        previous_inner_prediction = prediction
        previous_target = target
    return bytes(output)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""
    count = values[0]
    if not 1 <= count <= MAX_STEPS or len(values) != 1 + count * WORDS_PER_STEP:
        return INVALID_RESULT, b""
    steps = []
    cursor = 1
    for _ in range(count):
        cx0, cx1, target = values[cursor:cursor + 3]
        features = list(values[cursor + 3:cursor + 11])
        cursor += WORDS_PER_STEP
        if cx0 not in (0, 1) or cx1 not in (0, 1) or target not in (0, 1):
            return INVALID_RESULT, b""
        if any(value < -2047 or value > 2047 for value in features):
            return INVALID_RESULT, b""
        steps.append((cx0, cx1, target, features))
    if (type(output_is_null) is not bool or type(output_capacity) is not int
            or output_capacity < 0):
        return INVALID_RESULT, b""
    needed = 2 * count
    if output_is_null or output_capacity < needed:
        return OUTPUT_ERROR, b""
    return needed, _simulate(steps)


oracle = expected_output
