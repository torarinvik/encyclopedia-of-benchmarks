"""Independent state-machine oracle for the bounded Shootout methcall port."""
from __future__ import annotations

MIN_CALLS = -100_000
MAX_CALLS = 100_000
MAX_OUTPUT_BYTES = 14
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _line(state: bool) -> bytes:
    return (b"true" if state else b"false") + b"\n\n"


def expected_output(calls: int) -> tuple[int, bytes]:
    """Simulate both source loops and return their exact puts output bytes."""
    if type(calls) is not int or not MIN_CALLS <= calls <= MAX_CALLS:
        return INVALID_RESULT, b""

    toggle_state = True
    nth_state = True
    nth_counter = 0
    for _ in range(max(calls, 0)):
        toggle_state = not toggle_state
    for _ in range(max(calls, 0)):
        nth_counter += 1
        if nth_counter >= 3:
            nth_state = not nth_state
            nth_counter = 0

    output = _line(toggle_state) + _line(nth_state)
    return len(output), output
