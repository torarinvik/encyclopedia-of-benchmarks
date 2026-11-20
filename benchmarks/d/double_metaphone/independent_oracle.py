"""Independent action-stream reference for the pinned Double Metaphone rules."""

from __future__ import annotations

from dataclasses import dataclass

INVALID = -1
MAX_TEXT_BYTES = 32
MAX_KEY_BYTES = 4


def _valid_input_byte(value: int) -> bool:
    return (65 <= value <= 90 or 97 <= value <= 122 or value == 32
            or value in (0xC7, 0xE7, 0xD1, 0xF1))


def _fold_input_byte(value: int) -> int:
    if 97 <= value <= 122:
        return value - 32
    if value == 0xE7:
        return 0xC7
    if value == 0xF1:
        return 0xD1
    return value


@dataclass(frozen=True)
class _Context:
    text: bytes
    length: int
    slavo: bool

    def char(self, pos: int) -> int:
        return self.text[pos] if 0 <= pos < len(self.text) else 32

    def has(self, pos: int, token: bytes) -> bool:
        return pos >= 0 and pos + len(token) <= len(self.text) and self.text[pos:pos + len(token)] == token

    def one_of(self, pos: int, *tokens: bytes) -> bool:
        return any(self.has(pos, token) for token in tokens)

    def vowel(self, pos: int) -> bool:
        return 0 <= pos < self.length and self.char(pos) in b"AEIOUY"


def _same(ctx: _Context, pos: int, fragment: bytes, step: int = 1):
    return pos + step, fragment, fragment, False


def _fork(pos: int, first: bytes, second: bytes, step: int = 1):
    # A space-only second fragment denotes the original algorithm's suppressed
    # alternate contribution; an empty alternate fragment means copy the first.
    if second == b"":
        return pos + step, first, first, False
    if second == b" ":
        return pos + step, first, b"", True
    return pos + step, first, second, True


def _c(ctx: _Context, pos: int):
    if (pos > 1 and not ctx.vowel(pos - 2) and ctx.has(pos - 1, b"ACH")
            and ctx.char(pos + 2) != 73
            and (ctx.char(pos + 2) != 69
                 or ctx.one_of(pos - 2, b"BACHER", b"MACHER"))):
        return _same(ctx, pos, b"K", 2)
    if pos == 0 and ctx.has(pos, b"CAESAR"):
        return _same(ctx, pos, b"S", 2)
    if ctx.has(pos, b"CHIA"):
        return _same(ctx, pos, b"K", 2)
    if ctx.has(pos, b"CH"):
        if pos > 0 and ctx.has(pos, b"CHAE"):
            return _fork(pos, b"K", b"X", 2)
        if (pos == 0 and (ctx.one_of(pos + 1, b"HARAC", b"HARIS")
                          or ctx.one_of(pos + 1, b"HOR", b"HYM", b"HIA", b"HEM"))
                and not ctx.has(0, b"CHORE")):
            return _same(ctx, pos, b"K", 2)
        hard = (
            ctx.one_of(0, b"VAN ", b"VON ") or ctx.has(0, b"SCH")
            or ctx.one_of(pos - 2, b"ORCHES", b"ARCHIT", b"ORCHID")
            or ctx.one_of(pos + 2, b"T", b"S")
            or ((ctx.one_of(pos - 1, b"A", b"O", b"U", b"E") or pos == 0)
                and ctx.one_of(pos + 2, b"L", b"R", b"N", b"M", b"B",
                               b"H", b"F", b"V", b"W", b" "))
        )
        if hard:
            return _same(ctx, pos, b"K", 2)
        if pos > 0:
            return (_same(ctx, pos, b"K", 2) if ctx.has(0, b"MC")
                    else _fork(pos, b"X", b"K", 2))
        return _same(ctx, pos, b"X", 2)
    if ctx.has(pos, b"CZ") and not ctx.has(pos - 2, b"WICZ"):
        return _fork(pos, b"S", b"X", 2)
    if ctx.has(pos + 1, b"CIA"):
        return _same(ctx, pos, b"X", 3)
    if ctx.has(pos, b"CC") and not (pos == 1 and ctx.char(0) == 77):
        if ctx.one_of(pos + 2, b"I", b"E", b"H") and not ctx.has(pos + 2, b"HU"):
            if ((pos == 1 and ctx.char(pos - 1) == 65)
                    or ctx.one_of(pos - 1, b"UCCEE", b"UCCES")):
                return _same(ctx, pos, b"KS", 3)
            return _same(ctx, pos, b"X", 3)
        return _same(ctx, pos, b"K", 2)
    if ctx.one_of(pos, b"CK", b"CG", b"CQ"):
        return _same(ctx, pos, b"K", 2)
    if ctx.one_of(pos, b"CI", b"CE", b"CY"):
        return (_fork(pos, b"S", b"X", 2)
                if ctx.one_of(pos, b"CIO", b"CIE", b"CIA")
                else _same(ctx, pos, b"S", 2))
    if ctx.one_of(pos + 1, b" C", b" Q", b" G"):
        return _same(ctx, pos, b"K", 3)
    if (ctx.one_of(pos + 1, b"C", b"K", b"Q")
            and not ctx.one_of(pos + 1, b"CE", b"CI")):
        return _same(ctx, pos, b"K", 2)
    return _same(ctx, pos, b"K")


def _g(ctx: _Context, pos: int):
    if ctx.char(pos + 1) == 72:
        if pos > 0 and not ctx.vowel(pos - 1):
            return _same(ctx, pos, b"K", 2)
        if pos == 0:
            return _same(ctx, pos, b"J" if ctx.char(pos + 2) == 73 else b"K", 2)
        silent = ((pos > 1 and ctx.char(pos - 2) in b"BHD")
                  or (pos > 2 and ctx.char(pos - 3) in b"BHD")
                  or (pos > 3 and ctx.char(pos - 4) in b"BH"))
        if silent:
            return pos + 2, b"", b"", False
        if pos > 2 and ctx.char(pos - 1) == 85 and ctx.char(pos - 3) in b"CGLRT":
            return _same(ctx, pos, b"F", 2)
        if pos > 0 and ctx.char(pos - 1) != 73:
            return _same(ctx, pos, b"K", 2)
        return pos + 2, b"", b"", False
    if ctx.char(pos + 1) == 78:
        if pos == 1 and ctx.vowel(0) and not ctx.slavo:
            return _fork(pos, b"KN", b"N", 2)
        if (not ctx.has(pos + 2, b"EY") and ctx.char(pos + 1) != 89
                and not ctx.slavo):
            return _fork(pos, b"N", b"KN", 2)
        return _same(ctx, pos, b"KN", 2)
    if ctx.has(pos + 1, b"LI") and not ctx.slavo:
        return _fork(pos, b"KL", b"L", 2)
    front_initial = (ctx.char(pos + 1) == 89
                     or ctx.one_of(pos + 1, b"ES", b"EP", b"EB", b"EL", b"EY",
                                   b"IB", b"IL", b"IN", b"IE", b"EI", b"ER"))
    if pos == 0 and front_initial:
        return _fork(pos, b"K", b"J", 2)
    soft_cluster = ((ctx.has(pos + 1, b"ER") or ctx.char(pos + 1) == 89)
                    and not ctx.one_of(0, b"DANGER", b"RANGER", b"MANGER")
                    and not ctx.one_of(pos - 1, b"E", b"I")
                    and not ctx.one_of(pos - 1, b"RGY", b"OGY"))
    if soft_cluster:
        return _fork(pos, b"K", b"J", 2)
    if (ctx.char(pos + 1) in b"EIY"
            or ctx.one_of(pos - 1, b"AGGI", b"OGGI")):
        if (ctx.one_of(0, b"VAN ", b"VON ") or ctx.has(0, b"SCH")
                or ctx.has(pos + 1, b"ET")):
            return _same(ctx, pos, b"K", 2)
        if ctx.has(pos + 1, b"IER "):
            return _same(ctx, pos, b"J", 2)
        return _fork(pos, b"J", b"K", 2)
    return _same(ctx, pos, b"K", 2 if ctx.char(pos + 1) == 71 else 1)


def _j(ctx: _Context, pos: int):
    if ctx.has(pos, b"JOSE") or ctx.has(0, b"SAN "):
        if (pos == 0 and ctx.char(pos + 4) == 32) or ctx.has(0, b"SAN "):
            return _same(ctx, pos, b"H")
        return _fork(pos, b"J", b"H")
    if pos == 0:
        result = _fork(pos, b"J", b"A")
    elif (ctx.vowel(pos - 1) and not ctx.slavo and ctx.char(pos + 1) in b"AO"):
        result = _fork(pos, b"J", b"H")
    elif pos == ctx.length - 1:
        result = _fork(pos, b"J", b" ")
    elif (not ctx.one_of(pos + 1, b"L", b"T", b"K", b"S", b"N", b"M", b"B", b"Z")
          and not ctx.one_of(pos - 1, b"S", b"K", b"L")):
        result = _same(ctx, pos, b"J")
    else:
        result = pos + 1, b"", b"", False
    return (pos + 2, result[1], result[2], result[3]) if ctx.char(pos + 1) == 74 else result


def _l(ctx: _Context, pos: int):
    if ctx.char(pos + 1) != 76:
        return _same(ctx, pos, b"L")
    spanish = ((pos == ctx.length - 3
                and ctx.one_of(pos - 1, b"ILLO", b"ILLA", b"ALLE"))
               or ((ctx.one_of(ctx.length - 3, b"AS", b"OS")
                    or ctx.one_of(ctx.length - 1, b"A", b"O"))
                   and ctx.has(pos - 1, b"ALLE")))
    return (_fork(pos, b"L", b" ", 2) if spanish
            else _same(ctx, pos, b"L", 2))


def _r(ctx: _Context, pos: int):
    french = (pos == ctx.length - 1 and not ctx.slavo
              and ctx.has(pos - 2, b"IE")
              and not ctx.one_of(pos - 4, b"ME", b"MA"))
    result = _fork(pos, b"", b"R") if french else _same(ctx, pos, b"R")
    return (pos + 2, result[1], result[2], result[3]) if ctx.char(pos + 1) == 82 else result


def _s(ctx: _Context, pos: int):
    if ctx.one_of(pos - 1, b"ISL", b"YSL"):
        return pos + 1, b"", b"", False
    if pos == 0 and ctx.has(pos, b"SUGAR"):
        return _fork(pos, b"X", b"S")
    if ctx.has(pos, b"SH"):
        sound = b"S" if ctx.one_of(pos + 1, b"HEIM", b"HOEK", b"HOLM", b"HOLZ") else b"X"
        return _same(ctx, pos, sound, 2)
    if ctx.one_of(pos, b"SIO", b"SIA") or ctx.has(pos, b"SIAN"):
        return _fork(pos, b"S", b"X", 3) if not ctx.slavo else _same(ctx, pos, b"S", 3)
    initial_cluster = ((pos == 0 and ctx.one_of(pos + 1, b"M", b"N", b"L", b"W"))
                       or ctx.has(pos + 1, b"Z"))
    if initial_cluster:
        return _fork(pos, b"S", b"X", 2 if ctx.has(pos + 1, b"Z") else 1)
    if ctx.has(pos, b"SC"):
        if ctx.char(pos + 2) == 72:
            dutch = ctx.one_of(pos + 3, b"OO", b"ER", b"EN", b"UY", b"ED", b"EM")
            if dutch:
                if ctx.one_of(pos + 3, b"ER", b"EN"):
                    return _fork(pos, b"X", b"SK", 3)
                return _same(ctx, pos, b"SK", 3)
            if pos == 0 and not ctx.vowel(3) and ctx.char(3) != 87:
                return _fork(pos, b"X", b"S", 3)
            return _same(ctx, pos, b"X", 3)
        if ctx.one_of(pos + 2, b"I", b"E", b"Y"):
            return _same(ctx, pos, b"S", 3)
        return _same(ctx, pos, b"SK", 3)
    if pos == ctx.length - 1 and ctx.one_of(pos - 2, b"AI", b"OI"):
        result = _fork(pos, b"", b"S")
    else:
        result = _same(ctx, pos, b"S")
    return (pos + 2, result[1], result[2], result[3]) if ctx.one_of(pos + 1, b"S", b"Z") else result


def _t(ctx: _Context, pos: int):
    if ctx.has(pos, b"TION"):
        return _same(ctx, pos, b"X", 3)
    if ctx.one_of(pos, b"TIA", b"TCH"):
        return _same(ctx, pos, b"X", 3)
    if ctx.has(pos, b"TH") or ctx.has(pos, b"TTH"):
        if (ctx.one_of(pos + 2, b"OM", b"AM")
                or ctx.one_of(0, b"VAN ", b"VON ") or ctx.has(0, b"SCH")):
            return _same(ctx, pos, b"T", 2)
        return _fork(pos, b"0", b"T", 2)
    return _same(ctx, pos, b"T", 2 if ctx.one_of(pos + 1, b"T", b"D") else 1)


def _w(ctx: _Context, pos: int):
    if ctx.has(pos, b"WR"):
        return _same(ctx, pos, b"R", 2)
    prefix_output = None
    if pos == 0 and (ctx.vowel(pos + 1) or ctx.has(pos, b"WH")):
        prefix_output = _fork(pos, b"A", b"F") if ctx.vowel(pos + 1) else _same(ctx, pos, b"A")
    ending = ((pos == ctx.length - 1 and ctx.vowel(pos - 1))
              or ctx.one_of(pos - 1, b"EWSKI", b"EWSKY", b"OWSKI", b"OWSKY")
              or ctx.has(0, b"SCH"))
    if ending:
        tail = _fork(pos, b"", b"F")
        if prefix_output is None:
            return tail
        return pos + 1, prefix_output[1] + tail[1], prefix_output[2] + tail[2], prefix_output[3] or tail[3]
    if ctx.one_of(pos, b"WICZ", b"WITZ"):
        tail = _fork(pos, b"TS", b"FX", 4)
        if prefix_output is None:
            return tail
        return pos + 4, prefix_output[1] + tail[1], prefix_output[2] + tail[2], prefix_output[3] or tail[3]
    if prefix_output is not None:
        return pos + 1, prefix_output[1], prefix_output[2], prefix_output[3]
    return pos + 1, b"", b"", False


def _x(ctx: _Context, pos: int):
    french_tail = (pos == ctx.length - 1
                   and (ctx.one_of(pos - 3, b"IAU", b"EAU")
                        or ctx.one_of(pos - 2, b"AU", b"OU")))
    result = (pos + 1, b"", b"", False) if french_tail else _same(ctx, pos, b"KS")
    return (pos + 2, result[1], result[2], result[3]) if ctx.one_of(pos + 1, b"C", b"X") else result


def _z(ctx: _Context, pos: int):
    if ctx.char(pos + 1) == 72:
        return _same(ctx, pos, b"J", 2)
    if (ctx.one_of(pos + 1, b"ZO", b"ZI", b"ZA")
            or (ctx.slavo and pos > 0 and ctx.char(pos - 1) != 84)):
        result = _fork(pos, b"S", b"TS")
    else:
        result = _same(ctx, pos, b"S")
    return (pos + 2, result[1], result[2], result[3]) if ctx.char(pos + 1) == 90 else result


def _resolve(ctx: _Context, pos: int):
    symbol = ctx.char(pos)
    if symbol in b"AEIOUY":
        return _same(ctx, pos, b"A" if pos == 0 else b"")
    if symbol == 66:
        return _same(ctx, pos, b"P", 2 if ctx.char(pos + 1) == 66 else 1)
    if symbol == 0xC7:
        return _same(ctx, pos, b"S")
    if symbol == 67:
        return _c(ctx, pos)
    if symbol == 68:
        if ctx.has(pos, b"DG"):
            return _same(ctx, pos, b"J", 3) if ctx.one_of(pos + 2, b"I", b"E", b"Y") else _same(ctx, pos, b"TK", 2)
        if ctx.one_of(pos, b"DT", b"DD"):
            return _same(ctx, pos, b"T", 2)
        return _same(ctx, pos, b"T")
    if symbol == 70:
        return _same(ctx, pos, b"F", 2 if ctx.char(pos + 1) == 70 else 1)
    if symbol == 71:
        return _g(ctx, pos)
    if symbol == 72:
        return _same(ctx, pos, b"H", 2) if ((pos == 0 or ctx.vowel(pos - 1)) and ctx.vowel(pos + 1)) else (pos + 1, b"", b"", False)
    if symbol == 74:
        return _j(ctx, pos)
    if symbol == 75:
        return _same(ctx, pos, b"K", 2 if ctx.char(pos + 1) == 75 else 1)
    if symbol == 76:
        return _l(ctx, pos)
    if symbol == 77:
        mute_mb = (ctx.has(pos - 1, b"UMB")
                   and (pos + 1 == ctx.length - 1 or ctx.has(pos + 2, b"ER")))
        return _same(ctx, pos, b"M", 2 if mute_mb or ctx.char(pos + 1) == 77 else 1)
    if symbol == 78:
        return _same(ctx, pos, b"N", 2 if ctx.char(pos + 1) == 78 else 1)
    if symbol == 0xD1:
        return _same(ctx, pos, b"N")
    if symbol == 80:
        if ctx.char(pos + 1) == 72:
            return _same(ctx, pos, b"F", 2)
        return _same(ctx, pos, b"P", 2 if ctx.one_of(pos + 1, b"P", b"B") else 1)
    if symbol == 81:
        return _same(ctx, pos, b"K", 2 if ctx.char(pos + 1) == 81 else 1)
    if symbol == 82:
        return _r(ctx, pos)
    if symbol == 83:
        return _s(ctx, pos)
    if symbol == 84:
        return _t(ctx, pos)
    if symbol == 86:
        return _same(ctx, pos, b"F", 2 if ctx.char(pos + 1) == 86 else 1)
    if symbol == 87:
        return _w(ctx, pos)
    if symbol == 88:
        return _x(ctx, pos)
    if symbol == 90:
        return _z(ctx, pos)
    return pos + 1, b"", b"", False


def encode(raw: list[int] | tuple[int, ...]) -> tuple[bytes, bytes] | None:
    if not isinstance(raw, (list, tuple)) or not raw:
        return None
    if any(type(word) is not int for word in raw):
        return None
    length = raw[0]
    if length < 0 or length > MAX_TEXT_BYTES or len(raw) != length + 1:
        return None
    body = raw[1:]
    if any(not _valid_input_byte(byte) for byte in body):
        return None
    if length == 0:
        return b"", b""
    work = bytearray(b" " * (length + 5))
    for offset, byte in enumerate(body):
        work[offset] = _fold_input_byte(byte)
    normalized = bytes(work[:length])
    slavo = b"W" in normalized or b"K" in normalized or b"CZ" in normalized or b"WITZ" in normalized
    ctx = _Context(bytes(work), length, slavo)
    cursor = 1 if ctx.one_of(0, b"GN", b"KN", b"PN", b"WR", b"PS") else 0
    primary = bytearray()
    secondary = bytearray()
    has_alternate = False
    if ctx.char(0) == 88:
        primary.append(83)
        secondary.append(83)
        cursor = 1
    while cursor < length and (len(primary) < MAX_KEY_BYTES or len(secondary) < MAX_KEY_BYTES):
        cursor, first, second, alternate = _resolve(ctx, cursor)
        primary.extend(first)
        secondary.extend(second)
        has_alternate = has_alternate or alternate
    first_key = bytes(primary[:MAX_KEY_BYTES])
    second_key = bytes(secondary[:MAX_KEY_BYTES]) if has_alternate else b""
    return first_key, b"" if second_key == first_key else second_key


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    result = encode(values)
    if result is None:
        return INVALID, b""
    primary, secondary = result
    packed = bytes((len(primary), len(secondary))) + primary + secondary
    return len(packed), packed
