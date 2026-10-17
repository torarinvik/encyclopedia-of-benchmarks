"""Bounded independent oracle for McNaughton–Yamada–Thompson matching."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MIN_PATTERN_LENGTH = 0
MAX_PATTERN_LENGTH = 16
MIN_TEXT_LENGTH = 0
MAX_TEXT_LENGTH = 32
MAX_NFA_FRAGMENTS = 4
MAX_NFA_STATES = 2 * MAX_NFA_FRAGMENTS
MAX_VALID_INPUT_LENGTH = 2 + MAX_PATTERN_LENGTH + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1

_PATTERN_LITERALS = {ord("a"), ord("b"), ord("c")}
_PATTERN_OPERATORS = {ord("("), ord(")"), ord("*"), ord("|")}
_EPSILON = ("epsilon",)


class _PatternParser:
    """Parse only the reviewed, bounded grammar used by the workload."""

    def __init__(self, pattern: str) -> None:
        self.pattern = pattern
        self.position = 0

    def parse(self) -> tuple[object, ...] | None:
        if not self.pattern:
            return _EPSILON
        node = self._parse_union()
        if self.position != len(self.pattern):
            raise ValueError("unexpected pattern token")
        return node

    def _parse_union(self) -> tuple[object, ...]:
        node = self._parse_concat()
        while self._peek() == "|":
            self.position += 1
            node = ("union", node, self._parse_concat())
        return node

    def _parse_concat(self) -> tuple[object, ...]:
        if self._peek() in (None, ")", "|"):
            raise ValueError("empty concatenation")
        node = self._parse_repeat()
        while self._peek() not in (None, ")", "|"):
            node = ("concat", node, self._parse_repeat())
        return node

    def _parse_repeat(self) -> tuple[object, ...]:
        node = self._parse_atom()
        if self._peek() == "*":
            self.position += 1
            node = ("star", node)
        return node

    def _parse_atom(self) -> tuple[object, ...]:
        token = self._peek()
        if token is None:
            raise ValueError("missing atom")
        if token in "abc":
            self.position += 1
            return ("literal", ord(token))
        if token == "(":
            self.position += 1
            node = self._parse_union()
            if self._peek() != ")":
                raise ValueError("unclosed group")
            self.position += 1
            return node
        raise ValueError("unsupported pattern token")

    def _peek(self) -> str | None:
        if self.position >= len(self.pattern):
            return None
        return self.pattern[self.position]


def _fragment_count(node: tuple[object, ...]) -> int:
    operation = node[0]
    if operation == "epsilon":
        return 0
    if operation == "literal":
        return 1
    if operation == "star":
        return 1 + _fragment_count(node[1])  # type: ignore[arg-type]
    if operation in ("union", "concat"):
        own = int(operation == "union")
        return own + _fragment_count(node[1]) + _fragment_count(node[2])  # type: ignore[arg-type]
    raise ValueError("unknown syntax node")


def _source_parser_compatible(pattern: str) -> bool:
    """Reject syntax that buildAST misparses while stripping outer bytes."""
    if not pattern:
        return True

    def is_literal(token: str) -> bool:
        return token not in {"(", ")", "*", "\n", "|"}

    preprocessed: list[str] = []
    for index, token in enumerate(pattern):
        preprocessed.append(token)
        if index + 1 == len(pattern):
            continue
        following = pattern[index + 1]
        inserts_concat = (
            is_literal(token) and is_literal(following)
            or is_literal(token) and following == "("
            or token == ")" and following == "("
            or token == ")" and is_literal(following)
            or token == "*" and is_literal(following)
            or token == "*" and following == "("
        )
        if inserts_concat:
            preprocessed.append("\n")

    def parse_substring(source: str) -> bool:
        if not source:
            return True
        if len(source) == 1:
            return True
        if source[0] == "(" and source[-1] == ")":
            depth = 0
            for index, token in enumerate(source):
                if token == "(":
                    depth += 1
                elif token == ")":
                    depth -= 1
                if depth == 0 and index < len(source) - 1:
                    return False
            if depth != 0:
                return False
            return parse_substring(source[1:-1])

        for operator in ("|", "\n"):
            depth = 0
            for index, token in enumerate(source):
                if depth == 0 and token == operator:
                    return (parse_substring(source[:index])
                            and parse_substring(source[index + 1:]))
                if token == "(":
                    depth += 1
                elif token == ")":
                    depth -= 1

        # For a well-formed pattern, the remaining source parser branch is
        # its trailing postfix star, removed before recursively parsing.
        return source.endswith("*") and parse_substring(source[:-1])

    return parse_substring("".join(preprocessed))


def _parse_input(values: Sequence[int]) -> tuple[tuple[object, ...], tuple[int, ...]] | None:
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 2
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int for value in values)
    ):
        return None

    pattern_length, text_length = values[:2]
    if not MIN_PATTERN_LENGTH <= pattern_length <= MAX_PATTERN_LENGTH:
        return None
    if not MIN_TEXT_LENGTH <= text_length <= MAX_TEXT_LENGTH:
        return None
    if len(values) != 2 + pattern_length + text_length:
        return None

    pattern_bytes = values[2:2 + pattern_length]
    text_bytes = values[2 + pattern_length:]
    if any(not 1 <= byte <= 127 for byte in text_bytes):
        return None
    if any(byte not in _PATTERN_LITERALS | _PATTERN_OPERATORS for byte in pattern_bytes):
        return None

    pattern = bytes(pattern_bytes).decode("ascii")
    try:
        syntax_tree = _PatternParser(pattern).parse()
        if (syntax_tree is None
                or not _source_parser_compatible(pattern)
                or _fragment_count(syntax_tree) > MAX_NFA_FRAGMENTS):
            return None
    except (RecursionError, ValueError):
        return None
    return syntax_tree, tuple(text_bytes)


def _matches(syntax_tree: tuple[object, ...], text: tuple[int, ...]) -> bool:
    @lru_cache(maxsize=None)
    def reachable(node: tuple[object, ...], position: int) -> frozenset[int]:
        operation = node[0]
        if operation == "epsilon":
            return frozenset((position,))
        if operation == "literal":
            byte = node[1]
            if position < len(text) and text[position] == byte:
                return frozenset((position + 1,))
            return frozenset()
        if operation == "union":
            return reachable(node[1], position) | reachable(node[2], position)  # type: ignore[arg-type]
        if operation == "concat":
            ends: set[int] = set()
            for middle in reachable(node[1], position):  # type: ignore[arg-type]
                ends.update(reachable(node[2], middle))  # type: ignore[arg-type]
            return frozenset(ends)
        if operation == "star":
            child = node[1]
            seen = {position}
            pending = [position]
            while pending:
                current = pending.pop()
                for end in reachable(child, current):  # type: ignore[arg-type]
                    if end not in seen:
                        seen.add(end)
                        pending.append(end)
            return frozenset(seen)
        raise ValueError("unknown syntax node")

    return len(text) in reachable(syntax_tree, 0)


def expected_result(values: Sequence[int]) -> int:
    """Return 1 for a full match, 0 for a valid nonmatch, or -1 if invalid."""
    parsed = _parse_input(values)
    if parsed is None:
        return INVALID_RESULT
    syntax_tree, text = parsed
    return int(_matches(syntax_tree, text))
