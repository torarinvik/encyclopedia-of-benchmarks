"""Clean-room bounded reference for Philips's original Double Metaphone profile."""

from __future__ import annotations

from dataclasses import dataclass, field

MAX_TEXT_BYTES = 32
MAX_INPUT_WORDS = MAX_TEXT_BYTES + 1
MAX_PARSEABLE_WORDS = MAX_INPUT_WORDS + 1
MAX_KEY_BYTES = 4
MAX_OUTPUT_BYTES = 2 + 2 * MAX_KEY_BYTES
PAD_BYTES = 5
INVALID = -1
NO_OUTPUT = -2


def _upper_byte(value: int) -> int:
    if 97 <= value <= 122:
        return value - 32
    if value == 0xE7:
        return 0xC7
    if value == 0xF1:
        return 0xD1
    return value


def _accepted(value: int) -> bool:
    return (65 <= value <= 90 or 97 <= value <= 122 or value == 32
            or value in (0xC7, 0xE7, 0xD1, 0xF1))


@dataclass
class _Scan:
    letters: bytearray
    length: int
    slavo_germanic: bool
    primary: bytearray = field(default_factory=bytearray)
    secondary: bytearray = field(default_factory=bytearray)
    has_alternate: bool = False

    @classmethod
    def make(cls, raw: list[int]) -> _Scan:
        size = len(raw)
        padded = bytearray(b" " * (size + PAD_BYTES))
        for index, value in enumerate(raw):
            padded[index] = _upper_byte(value)
        latin = bytes(padded[:size])
        slavo = (b"W" in latin or b"K" in latin or b"CZ" in latin
                 or b"WITZ" in latin)
        return cls(padded, size, slavo)

    def at(self, index: int) -> int:
        if 0 <= index < len(self.letters):
            return self.letters[index]
        return 32

    def has(self, index: int, text: bytes) -> bool:
        if index < 0 or index + len(text) > len(self.letters):
            return False
        return self.letters[index:index + len(text)] == text

    def any_at(self, index: int, *texts: bytes) -> bool:
        return any(self.has(index, text) for text in texts)

    def vowel(self, index: int) -> bool:
        return 0 <= index < self.length and self.at(index) in b"AEIOUY"

    @staticmethod
    def _append_limited(target: bytearray, fragment: bytes) -> None:
        room = MAX_KEY_BYTES - len(target)
        if room > 0:
            target.extend(fragment[:room])

    def emit(self, main: bytes, alternate: bytes | None = None) -> None:
        if alternate is None:
            self._append_limited(self.primary, main)
            self._append_limited(self.secondary, main)
            return
        self._append_limited(self.primary, main)
        if alternate:
            self.has_alternate = True
            if alternate[0] != 32:
                self._append_limited(self.secondary, alternate)
        elif main and main[0] != 32:
            self._append_limited(self.secondary, main)

    def _c(self, index: int) -> int:
        if (index > 1 and not self.vowel(index - 2)
                and self.has(index - 1, b"ACH")
                and self.at(index + 2) != ord("I")
                and (self.at(index + 2) != ord("E")
                     or self.any_at(index - 2, b"BACHER", b"MACHER"))):
            self.emit(b"K")
            return index + 2
        if index == 0 and self.has(index, b"CAESAR"):
            self.emit(b"S")
            return index + 2
        if self.has(index, b"CHIA"):
            self.emit(b"K")
            return index + 2
        if self.has(index, b"CH"):
            if index > 0 and self.has(index, b"CHAE"):
                self.emit(b"K", b"X")
                return index + 2
            if (index == 0
                    and (self.any_at(index + 1, b"HARAC", b"HARIS")
                         or self.any_at(index + 1, b"HOR", b"HYM", b"HIA", b"HEM"))
                    and not self.has(0, b"CHORE")):
                self.emit(b"K")
                return index + 2
            hard_ch = (
                self.any_at(0, b"VAN ", b"VON ") or self.has(0, b"SCH")
                or self.any_at(index - 2, b"ORCHES", b"ARCHIT", b"ORCHID")
                or self.any_at(index + 2, b"T", b"S")
                or ((self.any_at(index - 1, b"A", b"O", b"U", b"E") or index == 0)
                    and self.any_at(index + 2, b"L", b"R", b"N", b"M", b"B",
                                    b"H", b"F", b"V", b"W", b" "))
            )
            if hard_ch:
                self.emit(b"K")
            elif index > 0:
                self.emit(b"K" if self.has(0, b"MC") else b"X",
                          None if self.has(0, b"MC") else b"K")
            else:
                self.emit(b"X")
            return index + 2
        if self.has(index, b"CZ") and not self.has(index - 2, b"WICZ"):
            self.emit(b"S", b"X")
            return index + 2
        if self.has(index + 1, b"CIA"):
            self.emit(b"X")
            return index + 3
        if self.has(index, b"CC") and not (index == 1 and self.at(0) == ord("M")):
            if (self.any_at(index + 2, b"I", b"E", b"H")
                    and not self.has(index + 2, b"HU")):
                if ((index == 1 and self.at(index - 1) == ord("A"))
                        or self.any_at(index - 1, b"UCCEE", b"UCCES")):
                    self.emit(b"KS")
                else:
                    self.emit(b"X")
                return index + 3
            self.emit(b"K")
            return index + 2
        if self.any_at(index, b"CK", b"CG", b"CQ"):
            self.emit(b"K")
            return index + 2
        if self.any_at(index, b"CI", b"CE", b"CY"):
            if self.any_at(index, b"CIO", b"CIE", b"CIA"):
                self.emit(b"S", b"X")
            else:
                self.emit(b"S")
            return index + 2
        self.emit(b"K")
        if self.any_at(index + 1, b" C", b" Q", b" G"):
            return index + 3
        if (self.any_at(index + 1, b"C", b"K", b"Q")
                and not self.any_at(index + 1, b"CE", b"CI")):
            return index + 2
        return index + 1

    def _g(self, index: int) -> int:
        if self.at(index + 1) == ord("H"):
            if index > 0 and not self.vowel(index - 1):
                self.emit(b"K")
                return index + 2
            if index == 0:
                self.emit(b"J" if self.at(index + 2) == ord("I") else b"K")
                return index + 2
            silent_gh = (
                (index > 1 and self.at(index - 2) in b"BHD")
                or (index > 2 and self.at(index - 3) in b"BHD")
                or (index > 3 and self.at(index - 4) in b"BH")
            )
            if silent_gh:
                return index + 2
            if (index > 2 and self.at(index - 1) == ord("U")
                    and self.at(index - 3) in b"CGLRT"):
                self.emit(b"F")
            elif index > 0 and self.at(index - 1) != ord("I"):
                self.emit(b"K")
            return index + 2
        if self.at(index + 1) == ord("N"):
            if index == 1 and self.vowel(0) and not self.slavo_germanic:
                self.emit(b"KN", b"N")
            elif (not self.has(index + 2, b"EY") and self.at(index + 1) != ord("Y")
                  and not self.slavo_germanic):
                self.emit(b"N", b"KN")
            else:
                self.emit(b"KN")
            return index + 2
        if self.has(index + 1, b"LI") and not self.slavo_germanic:
            self.emit(b"KL", b"L")
            return index + 2
        if (index == 0
                and (self.at(index + 1) == ord("Y")
                     or self.any_at(index + 1, b"ES", b"EP", b"EB", b"EL", b"EY",
                                    b"IB", b"IL", b"IN", b"IE", b"EI", b"ER"))):
            self.emit(b"K", b"J")
            return index + 2
        if ((self.has(index + 1, b"ER") or self.at(index + 1) == ord("Y"))
                and not self.any_at(0, b"DANGER", b"RANGER", b"MANGER")
                and not self.any_at(index - 1, b"E", b"I")
                and not self.any_at(index - 1, b"RGY", b"OGY")):
            self.emit(b"K", b"J")
            return index + 2
        if (self.at(index + 1) in b"EIY"
                or self.any_at(index - 1, b"AGGI", b"OGGI")):
            if (self.any_at(0, b"VAN ", b"VON ") or self.has(0, b"SCH")
                    or self.has(index + 1, b"ET")):
                self.emit(b"K")
            elif self.has(index + 1, b"IER "):
                self.emit(b"J")
            else:
                self.emit(b"J", b"K")
            return index + 2
        next_index = index + 2 if self.at(index + 1) == ord("G") else index + 1
        self.emit(b"K")
        return next_index

    def _j(self, index: int) -> int:
        if self.has(index, b"JOSE") or self.has(0, b"SAN "):
            if ((index == 0 and self.at(index + 4) == 32)
                    or self.has(0, b"SAN ")):
                self.emit(b"H")
            else:
                self.emit(b"J", b"H")
            return index + 1
        if index == 0:
            self.emit(b"J", b"A")
        elif (self.vowel(index - 1) and not self.slavo_germanic
              and self.at(index + 1) in b"AO"):
            self.emit(b"J", b"H")
        elif index == self.length - 1:
            self.emit(b"J", b" ")
        elif (not self.any_at(index + 1, b"L", b"T", b"K", b"S", b"N", b"M",
                              b"B", b"Z")
              and not self.any_at(index - 1, b"S", b"K", b"L")):
            self.emit(b"J")
        return index + (2 if self.at(index + 1) == ord("J") else 1)

    def _l(self, index: int) -> int:
        if self.at(index + 1) != ord("L"):
            self.emit(b"L")
            return index + 1
        spanish_ll = (
            (index == self.length - 3
             and self.any_at(index - 1, b"ILLO", b"ILLA", b"ALLE"))
            or ((self.any_at(self.length - 3, b"AS", b"OS")
                 or self.any_at(self.length - 1, b"A", b"O"))
                and self.has(index - 1, b"ALLE"))
        )
        if spanish_ll:
            self.emit(b"L", b" ")
            return index + 2
        self.emit(b"L")
        return index + 2

    def _r(self, index: int) -> int:
        french_tail = (
            index == self.length - 1 and not self.slavo_germanic
            and self.has(index - 2, b"IE")
            and not self.any_at(index - 4, b"ME", b"MA")
        )
        if french_tail:
            self.emit(b"", b"R")
        else:
            self.emit(b"R")
        return index + (2 if self.at(index + 1) == ord("R") else 1)

    def _s(self, index: int) -> int:
        if self.any_at(index - 1, b"ISL", b"YSL"):
            return index + 1
        if index == 0 and self.has(index, b"SUGAR"):
            self.emit(b"X", b"S")
            return index + 1
        if self.has(index, b"SH"):
            self.emit(b"S" if self.any_at(index + 1, b"HEIM", b"HOEK", b"HOLM", b"HOLZ")
                      else b"X")
            return index + 2
        if (self.any_at(index, b"SIO", b"SIA") or self.has(index, b"SIAN")):
            self.emit(b"S", b"X") if not self.slavo_germanic else self.emit(b"S")
            return index + 3
        if ((index == 0 and self.any_at(index + 1, b"M", b"N", b"L", b"W"))
                or self.has(index + 1, b"Z")):
            self.emit(b"S", b"X")
            return index + (2 if self.has(index + 1, b"Z") else 1)
        if self.has(index, b"SC"):
            if self.at(index + 2) == ord("H"):
                if self.any_at(index + 3, b"OO", b"ER", b"EN", b"UY", b"ED", b"EM"):
                    self.emit(b"X", b"SK") if self.any_at(index + 3, b"ER", b"EN") else self.emit(b"SK")
                elif index == 0 and not self.vowel(3) and self.at(3) != ord("W"):
                    self.emit(b"X", b"S")
                else:
                    self.emit(b"X")
                return index + 3
            if self.any_at(index + 2, b"I", b"E", b"Y"):
                self.emit(b"S")
            else:
                self.emit(b"SK")
            return index + 3
        if index == self.length - 1 and self.any_at(index - 2, b"AI", b"OI"):
            self.emit(b"", b"S")
        else:
            self.emit(b"S")
        return index + (2 if self.any_at(index + 1, b"S", b"Z") else 1)

    def _t(self, index: int) -> int:
        if self.has(index, b"TION"):
            self.emit(b"X")
            return index + 3
        if self.any_at(index, b"TIA", b"TCH"):
            self.emit(b"X")
            return index + 3
        if self.has(index, b"TH") or self.has(index, b"TTH"):
            if (self.any_at(index + 2, b"OM", b"AM")
                    or self.any_at(0, b"VAN ", b"VON ")
                    or self.has(0, b"SCH")):
                self.emit(b"T")
            else:
                self.emit(b"0", b"T")
            return index + 2
        self.emit(b"T")
        return index + (2 if self.any_at(index + 1, b"T", b"D") else 1)

    def _w(self, index: int) -> int:
        if self.has(index, b"WR"):
            self.emit(b"R")
            return index + 2
        if index == 0 and (self.vowel(index + 1) or self.has(index, b"WH")):
            self.emit(b"A", b"F") if self.vowel(index + 1) else self.emit(b"A")
        if ((index == self.length - 1 and self.vowel(index - 1))
                or self.any_at(index - 1, b"EWSKI", b"EWSKY", b"OWSKI", b"OWSKY")
                or self.has(0, b"SCH")):
            self.emit(b"", b"F")
            return index + 1
        if self.any_at(index, b"WICZ", b"WITZ"):
            self.emit(b"TS", b"FX")
            return index + 4
        return index + 1

    def _x(self, index: int) -> int:
        french_end = (index == self.length - 1
                      and (self.any_at(index - 3, b"IAU", b"EAU")
                           or self.any_at(index - 2, b"AU", b"OU")))
        if not french_end:
            self.emit(b"KS")
        return index + (2 if self.any_at(index + 1, b"C", b"X") else 1)

    def _z(self, index: int) -> int:
        if self.at(index + 1) == ord("H"):
            self.emit(b"J")
            return index + 2
        if (self.any_at(index + 1, b"ZO", b"ZI", b"ZA")
                or (self.slavo_germanic and index > 0
                    and self.at(index - 1) != ord("T"))):
            self.emit(b"S", b"TS")
        else:
            self.emit(b"S")
        return index + (2 if self.at(index + 1) == ord("Z") else 1)

    def encode(self) -> tuple[bytes, bytes]:
        index = 0
        if self.any_at(0, b"GN", b"KN", b"PN", b"WR", b"PS"):
            index = 1
        if self.at(0) == ord("X"):
            self.emit(b"S")
            index = 1

        while index < self.length and (len(self.primary) < MAX_KEY_BYTES
                                       or len(self.secondary) < MAX_KEY_BYTES):
            char = self.at(index)
            if char in b"AEIOUY":
                if index == 0:
                    self.emit(b"A")
                index += 1
            elif char == ord("B"):
                self.emit(b"P")
                index += 2 if self.at(index + 1) == ord("B") else 1
            elif char == 0xC7:
                self.emit(b"S")
                index += 1
            elif char == ord("C"):
                index = self._c(index)
            elif char == ord("D"):
                if self.has(index, b"DG"):
                    if self.any_at(index + 2, b"I", b"E", b"Y"):
                        self.emit(b"J")
                        index += 3
                    else:
                        self.emit(b"TK")
                        index += 2
                elif self.any_at(index, b"DT", b"DD"):
                    self.emit(b"T")
                    index += 2
                else:
                    self.emit(b"T")
                    index += 1
            elif char == ord("F"):
                self.emit(b"F")
                index += 2 if self.at(index + 1) == ord("F") else 1
            elif char == ord("G"):
                index = self._g(index)
            elif char == ord("H"):
                if ((index == 0 or self.vowel(index - 1)) and self.vowel(index + 1)):
                    self.emit(b"H")
                    index += 2
                else:
                    index += 1
            elif char == ord("J"):
                index = self._j(index)
            elif char == ord("K"):
                self.emit(b"K")
                index += 2 if self.at(index + 1) == ord("K") else 1
            elif char == ord("L"):
                index = self._l(index)
            elif char == ord("M"):
                mute_mb = (self.has(index - 1, b"UMB")
                           and ((index + 1 == self.length - 1)
                                or self.has(index + 2, b"ER")))
                index += 2 if mute_mb or self.at(index + 1) == ord("M") else 1
                self.emit(b"M")
            elif char == ord("N"):
                self.emit(b"N")
                index += 2 if self.at(index + 1) == ord("N") else 1
            elif char == 0xD1:
                self.emit(b"N")
                index += 1
            elif char == ord("P"):
                if self.at(index + 1) == ord("H"):
                    self.emit(b"F")
                    index += 2
                else:
                    self.emit(b"P")
                    index += 2 if self.any_at(index + 1, b"P", b"B") else 1
            elif char == ord("Q"):
                self.emit(b"K")
                index += 2 if self.at(index + 1) == ord("Q") else 1
            elif char == ord("R"):
                index = self._r(index)
            elif char == ord("S"):
                index = self._s(index)
            elif char == ord("T"):
                index = self._t(index)
            elif char == ord("V"):
                self.emit(b"F")
                index += 2 if self.at(index + 1) == ord("V") else 1
            elif char == ord("W"):
                index = self._w(index)
            elif char == ord("X"):
                index = self._x(index)
            elif char == ord("Z"):
                index = self._z(index)
            else:
                index += 1

        primary = bytes(self.primary)
        secondary = bytes(self.secondary) if self.has_alternate else b""
        if secondary == primary:
            secondary = b""
        return primary, secondary


def encode(raw: list[int] | tuple[int, ...]) -> tuple[bytes, bytes] | None:
    if not isinstance(raw, (list, tuple)) or not raw:
        return None
    if any(type(value) is not int for value in raw):
        return None
    byte_length = raw[0]
    if byte_length < 0 or byte_length > MAX_TEXT_BYTES:
        return None
    if len(raw) != byte_length + 1:
        return None
    data = list(raw[1:])
    if any(not _accepted(value) for value in data):
        return None
    if byte_length == 0:
        return b"", b""
    return _Scan.make(data).encode()


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return key serialization for the shared byte-output ABI, without capacity effects."""
    result = encode(values)
    if result is None:
        return INVALID, b""
    primary, secondary = result
    output = bytes((len(primary), len(secondary))) + primary + secondary
    return len(output), output
