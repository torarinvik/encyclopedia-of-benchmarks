"""Independent oracle for the bounded Embench slre search profile."""
from __future__ import annotations
from collections.abc import Sequence

MAX_TEXT = 24
MAX_PATTERN = 24
INVALID = -2


def oracle(values: Sequence[int]) -> int:
    if len(values) < 2 or any(type(x) is not int for x in values):
        return INVALID
    nt, np = values[0], values[1]
    if not 0 <= nt <= MAX_TEXT or not 0 <= np <= MAX_PATTERN or len(values) != 2 + nt + np:
        return INVALID
    text = values[2:2 + nt]
    pat = values[2 + nt:]
    if any(not 97 <= x <= 122 for x in text):
        return INVALID
    if any(not (97 <= x <= 122 or x in (ord('.'), ord('^'), ord('$'), ord('|'), ord('?'))) for x in pat):
        return INVALID
    anchored_start = bool(pat and pat[0] == ord('^'))
    if anchored_start:
        pat = pat[1:]
    anchored_end = bool(pat and pat[-1] == ord('$'))
    if anchored_end:
        pat = pat[:-1]
    if any(x in (ord('^'), ord('$')) for x in pat):
        return INVALID
    # Alternatives are nonempty sequences of literal/dot atoms with optional '?'.
    branches: list[list[tuple[int, bool]]] = [[]]
    i = 0
    while i < len(pat):
        if pat[i] == ord('|'):
            if not branches[-1]:
                return INVALID
            branches.append([])
            i += 1
            continue
        if pat[i] == ord('?'):
            return INVALID
        atom = pat[i]
        optional = i + 1 < len(pat) and pat[i + 1] == ord('?')
        branches[-1].append((atom, optional))
        i += 2 if optional else 1
    if not branches[-1]:
        return INVALID
    starts = (0,) if anchored_start else range(len(text) + 1)
    for start in starts:
        for branch in branches:
            pos = start
            matched = True
            for atom, optional in branch:
                hit = pos < len(text) and (atom == ord('.') or atom == text[pos])
                if hit:
                    pos += 1
                elif not optional:
                    matched = False
                    break
            if matched and (not anchored_end or pos == len(text)):
                return pos
    return -1
