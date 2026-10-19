"""Independent bounded reference for the Dhrystone 2.1 core profile."""

from __future__ import annotations

MAX_PARSEABLE_INPUT_LENGTH = 1
MAX_OUTPUT_BYTES = 19
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I1, I2, I3, I4, I5 = range(5)


class Record:
    def __init__(self):
        self.ptr = 0
        self.discr = 0
        self.enum = 0
        self.value = 0
        self.text = bytearray(31)


class State:
    def __init__(self):
        self.glob = 0
        self.boolean = 0
        self.ch1 = 0
        self.ch2 = 0
        self.arr1 = [0] * 50
        self.arr2 = [[0] * 50 for _ in range(50)]
        self.records = [Record(), Record()]


def _copy(dst: bytearray, text: bytes) -> None:
    dst[:] = bytes(31)
    dst[:len(text)] = text


def _compare(a: bytearray, b: bytearray) -> int:
    for x, y in zip(a, b):
        if x != y:
            return -1 if x < y else 1
        if x == 0:
            return 0
    return 0


def _func1(s: State, a: int, b: int) -> int:
    if a != b:
        return I1
    s.ch1 = a
    return I2


def _func3(e: int) -> bool:
    return e == I3


def _proc7(a: int, b: int) -> int:
    return b + (a + 2)


def _proc6(s: State, value: int) -> int:
    result = value if _func3(value) else I4
    if value == I1:
        return I1
    if value == I2:
        return I1 if s.glob > 100 else I4
    if value == I3:
        return I2
    if value == I5:
        return I3
    return result


def _proc3(s: State, reference: Record, field: str) -> None:
    if s.records[0].ptr >= 0:
        setattr(reference, field, s.records[0].ptr)
    s.records[0].value = _proc7(10, s.glob)


def _proc1(s: State) -> None:
    first = s.records[0]
    next_index = first.ptr
    second = s.records[next_index]
    second.ptr, second.discr, second.enum, second.value = first.ptr, first.discr, first.enum, first.value
    second.text[:] = first.text
    first.value = 5
    second.value = first.value
    second.ptr = first.ptr
    _proc3(s, second, "ptr")
    if second.discr == I1:
        second.value = 6
        second.enum = _proc6(s, first.enum)
        second.ptr = first.ptr
        second.value = _proc7(second.value, 10)
    else:
        first.ptr, first.discr, first.enum, first.value = second.ptr, second.discr, second.enum, second.value
        first.text[:] = second.text


def _proc2(s: State, value: int) -> int:
    loc = value + 10
    while True:
        if s.ch1 == ord("A"):
            loc -= 1
            value = loc - s.glob
            enum = I1
        else:
            enum = I2
        if enum == I1:
            return value


def _proc4(s: State) -> None:
    s.boolean = int(s.ch1 == ord("A")) | s.boolean
    s.ch2 = ord("B")


def _proc5(s: State) -> None:
    s.ch1 = ord("A")
    s.boolean = 0


def _proc8(s: State, a: int, b: int) -> None:
    loc = a + 5
    s.arr1[loc] = b
    s.arr1[loc + 1] = s.arr1[loc]
    s.arr1[loc + 30] = loc
    for i in (loc, loc + 1):
        s.arr2[loc][i] = loc
    s.arr2[loc][loc - 1] += 1
    s.arr2[loc + 20][loc] = s.arr1[loc]
    s.glob = 5


def _func2(s: State, a: bytearray, b: bytearray) -> bool:
    loc, ch = 2, 0
    while loc <= 2:
        if _func1(s, a[loc], b[loc + 1]) == I1:
            ch = ord("A")
            loc += 1
    if ord("W") <= ch < ord("Z"):
        loc = 7
    if ch == ord("R"):
        return True
    if _compare(a, b) > 0:
        s.glob = loc + 7
        return True
    return False


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if len(values) != 1 or input_length is not None and (type(input_length) is not int or input_length != 1):
        return INVALID_RESULT, b""
    if type(values[0]) is not int or not 1 <= values[0] <= 8:
        return INVALID_RESULT, b""

    s = State()
    first, second = s.records
    first.ptr, first.discr, first.enum, first.value = 1, I1, I3, 40
    _copy(first.text, b"DHRYSTONE PROGRAM, SOME STRING\0")
    str1, str2 = bytearray(31), bytearray(31)
    _copy(str1, b"DHRYSTONE PROGRAM, 1'ST STRING\0")
    s.arr2[8][7] = 10
    int1 = int2 = int3 = enum_loc = func2_false = 0

    for run in range(1, values[0] + 1):
        _proc5(s)
        _proc4(s)
        int1, int2 = 2, 3
        _copy(str2, b"DHRYSTONE PROGRAM, 2'ND STRING\0")
        enum_loc = I2
        func2_false = int(not _func2(s, str1, str2))
        while int1 < int2:
            int3 = 5 * int1 - int2
            int3 = _proc7(int1, int2)
            int1 += 1
        _proc8(s, int1, int3)
        _proc1(s)
        for ch in range(ord("A"), s.ch2 + 1):
            if enum_loc == _func1(s, ch, ord("C")):
                enum_loc = _proc6(s, I1)
                _copy(str2, b"DHRYSTONE PROGRAM, 3'RD STRING\0")
                int2 = run
                s.glob = run
        int2 = int2 * int1
        int1 = int2 // int3
        int2 = 7 * (int2 - int3) - int1
        int1 = _proc2(s, int1)

    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, b""
    values_out = [s.glob, s.boolean, s.ch1, s.ch2, s.arr1[8], s.arr2[8][7],
                  first.discr, first.enum, first.value, first.ptr,
                  second.discr, second.enum, second.value, second.ptr,
                  int1, int2, int3, enum_loc, func2_false]
    return MAX_OUTPUT_BYTES, bytes(v & 0xff for v in values_out)
