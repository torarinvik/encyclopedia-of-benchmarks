"""Independent oracle for the bounded Stanford IntMM output profile."""

ROWSIZE = 40
MAX_PASSES = 10
MAX_OUTPUT_BYTES = 80
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _matrices() -> tuple[list[int], list[int]]:
    """Generate the two row-major matrices from the pinned 16-bit LCG."""
    seed = 74755
    matrices: list[list[int]] = []
    for _ in range(2):
        matrix: list[int] = []
        for _ in range(ROWSIZE * ROWSIZE):
            seed = (seed * 1309 + 13849) & 65535
            matrix.append(seed % 120 - 60)
        matrices.append(matrix)
    return matrices[0], matrices[1]


def expected_output(pass_count: int) -> tuple[int, bytes]:
    """Return the exact decimal lines for the requested diagonal passes.

    The source reseeds before every pass, so its matrices are identical each
    time. The oracle computes only the diagonal cells that become visible in
    stdout instead of constructing the source's full result matrix.
    """
    if type(pass_count) is not int or not 1 <= pass_count <= MAX_PASSES:
        return INVALID_RESULT, b""

    a, b = _matrices()
    lines = []
    for diagonal in range(pass_count):
        total = sum(
            a[diagonal * ROWSIZE + inner] * b[inner * ROWSIZE + diagonal]
            for inner in range(ROWSIZE)
        )
        lines.append(f"{total}\n")
    output = "".join(lines).encode("ascii")
    return len(output), output
