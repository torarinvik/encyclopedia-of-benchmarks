"""Independent direct AST matcher; it does not use position masks or subsets."""
from __future__ import annotations

from functools import lru_cache


class Parser:
    def __init__(self, pattern: bytes):
        self.pattern = pattern
        self.at = 0
        self.positions = 0

    def parse(self):
        tree = self.expr()
        if self.at != len(self.pattern) or self.positions > 8:
            raise ValueError
        return tree

    def expr(self):
        arms = [self.concat()]
        while self.at < len(self.pattern) and self.pattern[self.at] == 124:
            self.at += 1
            arms.append(self.concat())
        return arms[0] if len(arms) == 1 else ("or", tuple(arms))

    def concat(self):
        items = []
        while self.at < len(self.pattern) and self.pattern[self.at] not in (124, 41):
            items.append(self.repeat())
        if not items:
            raise ValueError
        return items[0] if len(items) == 1 else ("seq", tuple(items))

    def repeat(self):
        item = self.atom()
        if self.at < len(self.pattern) and self.pattern[self.at] == 42:
            self.at += 1
            item = ("star", item)
        return item

    def atom(self):
        if self.at >= len(self.pattern):
            raise ValueError
        char = self.pattern[self.at]
        self.at += 1
        if char == 40:
            item = self.expr()
            if self.at >= len(self.pattern) or self.pattern[self.at] != 41:
                raise ValueError
            self.at += 1
            return item
        if char not in (97, 98, 99, 46):
            raise ValueError
        self.positions += 1
        return ("char", char)


def _match(tree, text: bytes, start: int, end: int) -> bool:
    @lru_cache(None)
    def ends(node, offset):
        kind = node[0]
        if kind == "char":
            if offset < end and (node[1] == 46 or node[1] == text[offset]):
                return frozenset((offset + 1,))
            return frozenset()
        if kind == "or":
            return frozenset().union(*(ends(child, offset) for child in node[1]))
        if kind == "seq":
            positions = frozenset((offset,))
            for child in node[1]:
                positions = frozenset().union(*(ends(child, p) for p in positions))
                if not positions:
                    break
            return positions
        child = node[1]
        reached = {offset}
        frontier = [offset]
        while frontier:
            point = frontier.pop()
            for following in ends(child, point):
                if following not in reached:
                    reached.add(following)
                    frontier.append(following)
        return frozenset(reached)

    return end in ends(tree, start)


def verify_result(values, result: int, payload: bytes, *,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    if input_is_null or len(values) < 2 or len(values) > 58:
        return result == -1 and payload == b""
    if input_length is not None and input_length != len(values):
        return result == -1 and payload == b""
    n, p = values[:2]
    if not 0 <= n <= 24 or not 1 <= p <= 32 or len(values) != 2 + n + p:
        return result == -1 and payload == b""
    raw = values[2:]
    if any(not 1 <= value <= 127 for value in raw):
        return result == -1 and payload == b""
    text = bytes(raw[:n])
    try:
        tree = Parser(bytes(raw[n:])).parse()
    except (ValueError, RecursionError):
        return result == -1 and payload == b""
    if n and (output_is_null or (output_capacity is not None and output_capacity < n)):
        return result == -2 and payload == b""
    expected = bytes(
        1 if any(_match(tree, text, start, end + 1) for start in range(end + 1)) else 0
        for end in range(n)
    )
    return result == n and payload == expected
