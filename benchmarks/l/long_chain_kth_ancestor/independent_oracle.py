"""Direct parent-stepping reference, independent of long-chain tables."""

from __future__ import annotations

from .primary_oracle import MAX_OUTPUT_BYTES, _decode


def _direct_answers(parent: list[int], queries: list[tuple[int, int]]) -> list[int]:
    answers: list[int] = []
    for vertex, distance in queries:
        current = vertex
        for _ in range(distance):
            if current < 0:
                break
            current = parent[current]
        answers.append(current)
    return answers


def expected_output(values, input_is_null: bool = False,
                    input_length: int | None = None,
                    output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1, b""
    _n, parent, queries = decoded
    required = 8 * len(queries)
    if type(output_is_null) is not bool or type(output_capacity) is not int:
        return -2, b""
    if output_is_null or output_capacity < required:
        return -2, b""
    answers = _direct_answers(parent, queries)
    return required, b"".join(answer.to_bytes(8, "little", signed=True) for answer in answers)
