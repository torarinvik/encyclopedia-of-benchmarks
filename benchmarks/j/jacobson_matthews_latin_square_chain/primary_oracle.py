"""Direct reference for the bounded Jacobson–Matthews 3-cycle chain."""
from __future__ import annotations

from struct import pack

MAX_N = 4
MAX_STEPS = 12
MAX_INPUT_LENGTH = 2 + MAX_STEPS
MAX_OUTPUT_BYTES = 528
WORKSPACE_BYTES = 4096


def _parse(values, input_is_null: bool, input_length: int | None):
    if values is None or input_is_null or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if input_length is not None and input_length != len(values):
        return None
    n, steps = values[:2]
    if not 2 <= n <= MAX_N or not 0 <= steps <= MAX_STEPS or len(values) != 2 + steps:
        return None
    return n, list(values[2:])


def _index(n: int, i: int, j: int, k: int) -> int:
    return (i * n + j) * n + k


def _moves(tensor: list[int], n: int):
    defects = [(_index(n, i, j, k), i, j, k)
               for i in range(n) for j in range(n) for k in range(n)
               if tensor[_index(n, i, j, k)] == -1]
    if len(defects) > 1:
        return None
    if defects:
        _, i, j, k = defects[0]
        i_options = [ip for ip in range(n) if ip != i and tensor[_index(n, ip, j, k)] == 1]
        j_options = [jp for jp in range(n) if jp != j and tensor[_index(n, i, jp, k)] == 1]
        k_options = [kp for kp in range(n) if kp != k and tensor[_index(n, i, j, kp)] == 1]
        if len(i_options) != 2 or len(j_options) != 2 or len(k_options) != 2:
            return None
        return [(i, j, k, ip, jp, kp)
                for ip in i_options for jp in j_options for kp in k_options]

    moves = []
    for i in range(n):
        for j in range(n):
            for k in range(n):
                if tensor[_index(n, i, j, k)] != 0:
                    continue
                ip = next((x for x in range(n) if tensor[_index(n, x, j, k)] == 1), None)
                jp = next((x for x in range(n) if tensor[_index(n, i, x, k)] == 1), None)
                kp = next((x for x in range(n) if tensor[_index(n, i, j, x)] == 1), None)
                if ip is None or jp is None or kp is None:
                    return None
                moves.append((i, j, k, ip, jp, kp))
    return moves if len(moves) == n**3 - n**2 else None


def _step(tensor: list[int], n: int, choice: int) -> bool:
    moves = _moves(tensor, n)
    if moves is None or not 0 <= choice < len(moves):
        return False
    i, j, k, ip, jp, kp = moves[choice]
    for a, b, c in ((i, j, k), (ip, jp, k), (ip, j, kp), (i, jp, kp)):
        tensor[_index(n, a, b, c)] += 1
    for a, b, c in ((ip, j, k), (i, jp, k), (i, j, kp), (ip, jp, kp)):
        tensor[_index(n, a, b, c)] -= 1
    return True


def solve(values, *, input_is_null: bool = False,
          input_length: int | None = None) -> tuple[int, list[int]] | None:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return None
    n, choices = parsed
    tensor = [int(k == (i + j) % n) for i in range(n) for j in range(n) for k in range(n)]
    for choice in choices:
        if not _step(tensor, n, choice):
            return None
    return n, tensor


def expected_output(values, *, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    result = solve(values, input_is_null=input_is_null, input_length=input_length)
    if result is None:
        return -1, b""
    n, tensor = result
    size = (2 + n**3) * 8
    if output_is_null or (capacity is not None and capacity < size):
        return -2, b""
    words = [n, len(values) - 2, *tensor]
    return size, b"".join(pack("<q", word) for word in words)
