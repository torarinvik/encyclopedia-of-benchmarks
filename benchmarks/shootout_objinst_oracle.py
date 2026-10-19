"""Independent oracle for the pinned Shootout object-instantiation benchmark."""
from __future__ import annotations

MIN_N = -100_000
MAX_N = 100_000
MAX_OUTPUT_BYTES = 72
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _source_stdout() -> bytes:
    """Simulate the fixed Toggle/NthToggle dispatches and puts framing."""
    output = bytearray()

    state = True
    for _ in range(5):
        state = not state
        output.extend(b"true\n" if state else b"false\n")

    # The source calls puts("") between its Toggle and NthToggle sections.
    output.append(0x0A)

    state = True
    counter = 0
    for _ in range(8):
        counter += 1
        if counter >= 3:
            state = not state
            counter = 0
        output.extend(b"true\n" if state else b"false\n")
    return bytes(output)


SOURCE_STDOUT = _source_stdout()


def expected_output(n: int) -> tuple[int, bytes]:
    """Return the fixed source output for a bounded constructor-loop count."""
    if type(n) is not int or not MIN_N <= n <= MAX_N:
        return INVALID_RESULT, b""
    return len(SOURCE_STDOUT), SOURCE_STDOUT
