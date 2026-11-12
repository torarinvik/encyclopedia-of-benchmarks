"""Incremental fixed-base Schreier–Sims reference oracle."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_N = 6
MAX_GENERATORS = 4
MAX_QUERIES = 8
MAX_INPUT = 76
MAX_OUTPUT_BYTES = 72
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

Permutation = tuple[int, ...]


def _identity(n: int) -> Permutation:
    return tuple(range(n))


def _compose(first: Permutation, second: Permutation) -> Permutation:
    """Apply first, then second (right-action composition)."""
    return tuple(second[first[i]] for i in range(len(first)))


def _inverse(permutation: Permutation) -> Permutation:
    result = [0] * len(permutation)
    for point, image in enumerate(permutation):
        result[image] = point
    return tuple(result)


class _Layer:
    __slots__ = ("generators", "orbit", "transversal")

    def __init__(self, base: int, identity: Permutation):
        self.generators: list[Permutation] = []
        self.orbit: list[int] = [base]
        self.transversal: dict[int, Permutation] = {base: identity}


def _build_chain(n: int, generators: list[Permutation]):
    identity = _identity(n)
    layers = []
    for base in range(n):
        layers.append(_Layer(base, identity))

    pending: list[tuple[int, Permutation]] = [(0, g) for g in generators]
    cursor = 0
    while cursor < len(pending):
        start, candidate = pending[cursor]
        cursor += 1
        residue = candidate
        inserted_at = n
        for level in range(start, n):
            image = residue[level]
            layer = layers[level]
            representative = layer.transversal.get(image)
            if representative is None:
                inserted_at = level
                break
            residue = _compose(residue, _inverse(representative))
        if residue == identity or inserted_at == n:
            continue

        layer = layers[inserted_at]
        inverse_residue = _inverse(residue)
        if residue in layer.generators:
            continue
        layer.generators.append(residue)
        if inverse_residue != residue:
            layer.generators.append(inverse_residue)

        # Rebuild this layer's orbit representatives from its symmetric strong
        # generator set, then feed every Schreier residue to the next layer.
        layer.orbit = [inserted_at]
        layer.transversal = {inserted_at: identity}
        orbit_cursor = 0
        while orbit_cursor < len(layer.orbit):
            point = layer.orbit[orbit_cursor]
            orbit_cursor += 1
            representative = layer.transversal[point]
            for generator in layer.generators:
                image = generator[point]
                if image not in layer.transversal:
                    layer.transversal[image] = _compose(representative, generator)
                    layer.orbit.append(image)
        if inserted_at + 1 < n:
            for point in layer.orbit:
                representative = layer.transversal[point]
                for generator in layer.generators:
                    image = generator[point]
                    schreier = _compose(
                        _compose(representative, generator),
                        _inverse(layer.transversal[image]),
                    )
                    if schreier != identity:
                        pending.append((inserted_at + 1, schreier))
    return layers


def _is_member(layers, permutation: Permutation, n: int) -> bool:
    identity = _identity(n)
    residue = permutation
    for level, layer in enumerate(layers):
        representative = layer.transversal.get(residue[level])
        if representative is None:
            return False
        residue = _compose(residue, _inverse(representative))
    return residue == identity


def _parse(values: Sequence[int] | None, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if len(values) < 3 or len(values) > MAX_INPUT:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, generator_count, query_count = values[:3]
    if not 1 <= n <= MAX_N or not 0 <= generator_count <= MAX_GENERATORS or not 1 <= query_count <= MAX_QUERIES:
        return None
    if len(values) != 3 + n * (generator_count + query_count):
        return None
    cursor = 3
    permutations = []
    for _ in range(generator_count + query_count):
        permutation = tuple(values[cursor : cursor + n])
        cursor += n
        if any(not 0 <= image < n for image in permutation) or len(set(permutation)) != n:
            return None
        permutations.append(permutation)
    return n, permutations[:generator_count], permutations[generator_count:]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, generators, queries = parsed
    required = 8 * (1 + len(queries))
    if output_is_null or output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR, b""
    layers = _build_chain(n, generators)
    order = 1
    for layer in layers:
        order *= len(layer.orbit)
    answers = [order]
    answers.extend(int(_is_member(layers, query, n)) for query in queries)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
