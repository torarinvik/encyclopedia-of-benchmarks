"""Independent oracle for the bounded binary mutation operator."""

from __future__ import annotations

import math
from typing import Sequence


MAX_GENES = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_GENES
MAX_OUTPUT_ELEMENTS = MAX_GENES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _number(value: object) -> float | None:
    if type(value) not in (int, float):
        return None
    number = float(value)
    return number if math.isfinite(number) else None


def _exact_int(value: object) -> int | None:
    number = _number(value)
    if number is None or number != math.floor(number):
        return None
    return int(number)


def expected_result(values: Sequence[float]) -> list[float] | None:
    """Return the mutated binary genome, or ``None`` for invalid input."""
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None

    mu = _number(values[0])
    gene_count = _exact_int(values[1])
    if (mu is None or not 0.0 <= mu <= 1.0 or gene_count is None
            or not 0 <= gene_count <= MAX_GENES
            or len(values) != 2 + 2 * gene_count):
        return None

    genes: list[float] = []
    draws: list[float] = []
    gene_end = 2 + gene_count
    for value in values[2:gene_end]:
        gene = _number(value)
        if gene not in (0.0, 1.0):
            return None
        genes.append(gene)
    for value in values[gene_end:]:
        draw = _number(value)
        if draw is None or not 0.0 <= draw < 1.0:
            return None
        draws.append(draw)

    return [1.0 - gene if draw < mu else gene
            for gene, draw in zip(genes, draws)]
