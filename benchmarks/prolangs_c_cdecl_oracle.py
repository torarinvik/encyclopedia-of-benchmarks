"""Independent oracle for the bounded clean-room cdecl declarator parser."""

from __future__ import annotations

import re
from typing import Sequence

MAX_INPUT = 96
MAX_NAME = 16
MAX_OPS = 12
MAX_DEPTH = 6
MAX_PARAMS = 3
MAX_OUTPUT = 128
BASE_TYPES = {"char": 1, "int": 2, "float": 3, "double": 4, "void": 5}
TOKEN_RE = re.compile(r"[A-Za-z_][A-Za-z_0-9]*|[0-9]+|[()*\[\],]")


class Invalid(Exception):
    pass


class Reader:
    def __init__(self, source: str) -> None:
        self.source = source
        self.tokens: list[str] = []
        pos = 0
        while pos < len(source):
            if source[pos] in " \t\n\r":
                pos += 1
                continue
            match = TOKEN_RE.match(source, pos)
            if match is None:
                raise Invalid
            self.tokens.append(match.group())
            pos = match.end()
        self.pos = 0

    def peek(self) -> str | None:
        return self.tokens[self.pos] if self.pos < len(self.tokens) else None

    def take(self, expected: str | None = None) -> str:
        token = self.peek()
        if token is None or (expected is not None and token != expected):
            raise Invalid
        self.pos += 1
        return token

    def base_type(self) -> int:
        token = self.take()
        if token not in BASE_TYPES:
            raise Invalid
        return BASE_TYPES[token]

    def parameter(self) -> tuple[int, int]:
        base = self.base_type()
        depth = 0
        while self.peek() == "*":
            self.take("*")
            depth += 1
            if depth > 8:
                raise Invalid
        return base, depth

    def params(self) -> list[tuple[int, int]]:
        self.take("(")
        args: list[tuple[int, int]] = []
        if self.peek() == ")":
            self.take(")")
            return args
        while True:
            args.append(self.parameter())
            if len(args) > MAX_PARAMS:
                raise Invalid
            if self.peek() == ")":
                self.take(")")
                break
            self.take(",")
        if args == [(BASE_TYPES["void"], 0)]:
            return []
        if any(base == BASE_TYPES["void"] and depth == 0 for base, depth in args):
            raise Invalid
        return args

    def declarator(self, name: list[str], ops: list[tuple], depth: int = 0) -> None:
        if depth > MAX_DEPTH:
            raise Invalid
        pointers = 0
        while self.peek() == "*":
            self.take("*")
            pointers += 1
            if pointers > 8:
                raise Invalid
        if self.peek() == "(":
            self.take("(")
            self.declarator(name, ops, depth + 1)
            self.take(")")
        else:
            token = self.take()
            if not re.fullmatch(r"[A-Za-z_][A-Za-z_0-9]*", token) or name:
                raise Invalid
            if len(token) > MAX_NAME:
                raise Invalid
            name.append(token)
        while self.peek() in ("[", "("):
            if self.peek() == "[":
                self.take("[")
                number = self.take()
                if not number.isdecimal() or not 1 <= int(number) <= 99:
                    raise Invalid
                self.take("]")
                ops.append((2, int(number)))
            else:
                ops.append((3, self.params()))
            if len(ops) > MAX_OPS:
                raise Invalid
        ops.extend((1,) for _ in range(pointers))
        if len(ops) > MAX_OPS:
            raise Invalid


def _valid_type_order(base: int, ops: list[tuple]) -> bool:
    current_kind = "base"
    is_void = base == BASE_TYPES["void"]
    for op in reversed(ops):
        kind = op[0]
        if kind == 2:
            if current_kind == "function" or (current_kind == "base" and is_void):
                return False
            current_kind, is_void = "array", False
        elif kind == 3:
            if current_kind in ("array", "function"):
                return False
            current_kind, is_void = "function", False
        elif kind == 1:
            current_kind, is_void = "pointer", False
        else:
            return False
    return True


def _parse(values: Sequence[int]) -> bytes:
    if not values or len(values) > MAX_INPUT:
        raise Invalid
    if any(type(value) is not int or value <= 0 or value > 127 for value in values):
        raise Invalid
    source = "".join(chr(value) for value in values)
    reader = Reader(source)
    base = reader.base_type()
    name: list[str] = []
    ops: list[tuple] = []
    reader.declarator(name, ops)
    if reader.peek() is not None or not _valid_type_order(base, ops) or (base == BASE_TYPES["void"] and not ops):
        raise Invalid

    identifier = name[0].encode("ascii")
    if identifier in (b"char", b"int", b"float", b"double", b"void"):
        raise Invalid
    encoded = bytearray((base, len(identifier), *identifier, len(ops)))
    for op in ops:
        encoded.append(op[0])
        if op[0] == 2:
            encoded.append(op[1])
        elif op[0] == 3:
            encoded.append(len(op[1]))
            for arg_base, pointer_depth in op[1]:
                encoded.extend((arg_base, pointer_depth))
    if len(encoded) > MAX_OUTPUT:
        raise Invalid
    return bytes(encoded)


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool or input_is_null:
        return -1, b""
    if not isinstance(values, (tuple, list)):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -2, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or input_length < 1 or input_length > MAX_INPUT):
        return -1, b""
    try:
        result = _parse(values)
    except (Invalid, OverflowError, ValueError):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return -2, b""
    return len(result), result
