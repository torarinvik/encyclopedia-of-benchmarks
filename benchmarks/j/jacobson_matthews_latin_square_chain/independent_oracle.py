"""Independent exhaustive transition verifier for the Latin-square chain."""
from __future__ import annotations

from itertools import product
from struct import unpack


def _idx(n: int, cell: tuple[int, int, int]) -> int:
    i, j, k = cell
    return (i * n + j) * n + k


def _invariant(tensor: list[int], n: int) -> bool:
    if any(value not in (-1, 0, 1) for value in tensor) or tensor.count(-1) > 1:
        return False
    for i in range(n):
        for j in range(n):
            if sum(tensor[_idx(n, (i, j, k))] for k in range(n)) != 1:
                return False
    for i in range(n):
        for k in range(n):
            if sum(tensor[_idx(n, (i, j, k))] for j in range(n)) != 1:
                return False
    for j in range(n):
        for k in range(n):
            if sum(tensor[_idx(n, (i, j, k))] for i in range(n)) != 1:
                return False
    return True


def _enumerated_moves(tensor: list[int], n: int):
    defects = [cell for cell in product(range(n), repeat=3) if tensor[_idx(n, cell)] == -1]
    if len(defects) > 1:
        return None
    if defects:
        i, j, k = defects[0]
        candidates = []
        for ip, jp, kp in product(range(n), repeat=3):
            if (ip != i and jp != j and kp != k
                    and tensor[_idx(n, (i, j, kp))] == 1
                    and tensor[_idx(n, (i, jp, k))] == 1
                    and tensor[_idx(n, (ip, j, k))] == 1):
                candidates.append((i, j, k, ip, jp, kp))
        return candidates if len(candidates) == 8 else None

    candidates = []
    for i, j, k in product(range(n), repeat=3):
        if tensor[_idx(n, (i, j, k))] != 0:
            continue
        mates = [tuple for tuple in product(range(n), repeat=3)
                 if tuple[0] != i and tuple[1] != j and tuple[2] != k
                 and tensor[_idx(n, (tuple[0], j, k))] == 1
                 and tensor[_idx(n, (i, tuple[1], k))] == 1
                 and tensor[_idx(n, (i, j, tuple[2]))] == 1]
        if len(mates) != 1:
            return None
        ip, jp, kp = mates[0]
        candidates.append((i, j, k, ip, jp, kp))
    return candidates if len(candidates) == n**3 - n**2 else None


def _apply_by_corner_parity(tensor: list[int], n: int,
                            move: tuple[int, int, int, int, int, int]) -> bool:
    i, j, k, ip, jp, kp = move
    axes = ((i, ip), (j, jp), (k, kp))
    for mask in range(8):
        cell = tuple(axes[axis][(mask >> axis) & 1] for axis in range(3))
        tensor[_idx(n, cell)] += 1 if mask.bit_count() % 2 == 0 else -1
    return _invariant(tensor, n)


def _parse(values, input_is_null: bool, input_length: int | None):
    if values is None or input_is_null or len(values) < 2 or len(values) > 14:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if input_length is not None and input_length != len(values):
        return None
    n, steps = values[:2]
    if not 2 <= n <= 4 or not 0 <= steps <= 12 or len(values) != 2 + steps:
        return None
    return n, values[2:]


def verify_result(values, result: int, payload: bytes, *,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return result == -1 and payload == b""
    n, choices = parsed
    size = (2 + n**3) * 8
    if output_is_null or (output_capacity is not None and output_capacity < size):
        return result == -2 and payload == b""
    if result != size or len(payload) != size:
        return False
    words = unpack("<" + "q" * (2 + n**3), payload)
    if words[:2] != (n, len(choices)):
        return False
    tensor = [int(k == (i + j) % n) for i in range(n) for j in range(n) for k in range(n)]
    if not _invariant(tensor, n):
        return False
    for choice in choices:
        moves = _enumerated_moves(tensor, n)
        if moves is None or not 0 <= choice < len(moves):
            return False
        if not _apply_by_corner_parity(tensor, n, moves[choice]):
            return False
    return list(words[2:]) == tensor
