"""Independent oracle for the bounded Stanford Towers workload."""
from __future__ import annotations

MIN_RUNS = 1
MAX_RUNS = 100
DISK_COUNT = 14
EXPECTED_MOVES = (1 << DISK_COUNT) - 1
MAX_OUTPUT_BYTES = 600
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _solve_hanoi() -> int:
    """Simulate legal Hanoi moves using three ordinary Python stacks."""
    pegs = [list(range(DISK_COUNT, 0, -1)), [], []]

    def move(disks: int, source: int, destination: int, auxiliary: int) -> int:
        if disks == 0:
            return 0
        count = move(disks - 1, source, auxiliary, destination)
        disk = pegs[source].pop()
        if pegs[destination] and pegs[destination][-1] < disk:
            raise RuntimeError("oracle generated an illegal Hanoi move")
        pegs[destination].append(disk)
        count += 1
        return count + move(disks - 1, auxiliary, destination, source)

    moves = move(DISK_COUNT, 0, 1, 2)
    if pegs != [[], list(range(DISK_COUNT, 0, -1)), []]:
        raise RuntimeError("oracle did not move every disk to the destination")
    return moves


def expected_output(runs: int) -> tuple[int, bytes]:
    """Return repeated source output for one through one hundred passes."""
    if type(runs) is not int or not MIN_RUNS <= runs <= MAX_RUNS:
        return INVALID_RESULT, b""
    moves = _solve_hanoi()
    diagnostic = " Error in Towers.\n" if moves != EXPECTED_MOVES else ""
    output = (diagnostic + f"{moves}\n") * runs
    encoded = output.encode("ascii")
    return len(encoded), encoded
