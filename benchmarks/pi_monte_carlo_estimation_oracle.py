"""Independent oracle for the seeded CPython-compatible Monte Carlo π trace."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_SIMULATIONS = 1
MAX_SIMULATIONS = 100_000
MIN_SEED = 0
MAX_SEED = (1 << 32) - 1
MAX_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 0.0
RELATIVE_TOLERANCE = 0.0
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

_WORD_MASK = 0xFFFF_FFFF
_N = 624
_M = 397
_MATRIX_A = 0x9908_B0DF
_UPPER_MASK = 0x8000_0000
_LOWER_MASK = 0x7FFF_FFFF


class _CPythonMT19937:
    """MT19937 initialized like CPython's ``random.Random(int_seed)``."""

    def __init__(self, seed: int) -> None:
        self._state = [0] * _N
        self._state[0] = 19_650_218
        for index in range(1, _N):
            previous = self._state[index - 1]
            self._state[index] = (
                1_812_433_253 * (previous ^ (previous >> 30)) + index
            ) & _WORD_MASK

        # The workload restricts seed to one unsigned 32-bit word, including 0.
        key = [seed]
        index = 1
        key_index = 0
        for _ in range(max(_N, len(key))):
            previous = self._state[index - 1]
            self._state[index] = (
                (self._state[index]
                 ^ ((previous ^ (previous >> 30)) * 1_664_525))
                + key[key_index]
                + key_index
            ) & _WORD_MASK
            index += 1
            key_index += 1
            if index >= _N:
                self._state[0] = self._state[_N - 1]
                index = 1
            if key_index >= len(key):
                key_index = 0

        for _ in range(_N - 1):
            previous = self._state[index - 1]
            self._state[index] = (
                (self._state[index]
                 ^ ((previous ^ (previous >> 30)) * 1_566_083_941))
                - index
            ) & _WORD_MASK
            index += 1
            if index >= _N:
                self._state[0] = self._state[_N - 1]
                index = 1

        self._state[0] = _UPPER_MASK
        self._index = _N

    def _next_uint32(self) -> int:
        if self._index >= _N:
            state = self._state
            for index in range(_N - _M):
                joined = (state[index] & _UPPER_MASK) | (state[index + 1] & _LOWER_MASK)
                state[index] = state[index + _M] ^ (joined >> 1)
                if joined & 1:
                    state[index] ^= _MATRIX_A
            for index in range(_N - _M, _N - 1):
                joined = (state[index] & _UPPER_MASK) | (state[index + 1] & _LOWER_MASK)
                state[index] = state[index + (_M - _N)] ^ (joined >> 1)
                if joined & 1:
                    state[index] ^= _MATRIX_A
            joined = (state[_N - 1] & _UPPER_MASK) | (state[0] & _LOWER_MASK)
            state[_N - 1] = state[_M - 1] ^ (joined >> 1)
            if joined & 1:
                state[_N - 1] ^= _MATRIX_A
            self._index = 0

        value = self._state[self._index]
        self._index += 1
        value ^= value >> 11
        value ^= (value << 7) & 0x9D2C_5680
        value ^= (value << 15) & 0xEFC6_0000
        value ^= value >> 18
        return value & _WORD_MASK

    def random(self) -> float:
        """Return the CPython 53-bit ``random()`` construction."""
        high = self._next_uint32() >> 5
        low = self._next_uint32() >> 6
        return (high * 67_108_864.0 + low) * (1.0 / 9_007_199_254_740_992.0)


def _exact_integer(value: object) -> int | None:
    if type(value) is int:
        return value
    if type(value) is not float or not math.isfinite(value) or not value.is_integer():
        return None
    return int(value)


def _finite_number(value: object) -> bool:
    if type(value) is int:
        return True
    return type(value) is float and math.isfinite(value)


def _valid_parameters(values: Sequence[int | float] | None) -> tuple[int, int] | None:
    if (
        not isinstance(values, (list, tuple))
        or len(values) != MAX_INPUT_LENGTH
        or any(not _finite_number(value) for value in values)
    ):
        return None

    simulations = _exact_integer(values[0])
    seed = _exact_integer(values[1])
    if simulations is None or not MIN_SIMULATIONS <= simulations <= MAX_SIMULATIONS:
        return None
    if seed is None or not MIN_SEED <= seed <= MAX_SEED:
        return None
    return simulations, seed


def _estimate(simulations: int, seed: int) -> float:
    rng = _CPythonMT19937(seed)
    hits = 0
    for _ in range(simulations):
        x = rng.random()
        y = rng.random()
        if x * x + y * y <= 1.0:
            hits += 1
    return 4 * hits / simulations


def expected_result(values: Sequence[int | float] | None) -> list[float] | None:
    """Return the estimate as a single output element, or None if invalid."""
    parameters = _valid_parameters(values)
    if parameters is None:
        return None
    return [_estimate(*parameters)]


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return result code and output values for the float64-slice ABI."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, []

    output = expected_result(values)
    if output is None:
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < MAX_OUTPUT_ELEMENTS
    ):
        return OUTPUT_ERROR, []
    return len(output), output
