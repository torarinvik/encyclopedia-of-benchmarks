"""Independent oracle for the bounded Stanford RealMM stdout profile."""

ROWSIZE = 40
MAX_PASSES = 10
MAX_OUTPUT_BYTES = 14 * MAX_PASSES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _matrix(seed: int) -> tuple[list[float], int]:
    """Regenerate one row-major double matrix using the source's 16-bit LCG."""
    matrix: list[float] = []
    for _ in range(ROWSIZE * ROWSIZE):
        seed = (seed * 1309 + 13849) & 65535
        temp = seed
        residue = temp - (temp // 120) * 120 - 60
        matrix.append(float(residue) / 3.0)
    return matrix, seed


def expected_output(pass_count: int) -> tuple[int, bytes]:
    """Compute only the diagonal dot products made visible by the launcher."""
    if type(pass_count) is not int or not 1 <= pass_count <= MAX_PASSES:
        return INVALID_RESULT, b""

    a, seed = _matrix(74755)
    b, _ = _matrix(seed)
    lines: list[str] = []
    for diagonal in range(pass_count):
        total = 0.0
        for inner in range(ROWSIZE):
            total = total + a[diagonal * ROWSIZE + inner] * b[inner * ROWSIZE + diagonal]
        lines.append(f"{total:.6f}\n")
    output = "".join(lines).encode("ascii")
    return len(output), output
