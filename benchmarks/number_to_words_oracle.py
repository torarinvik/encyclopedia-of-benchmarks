"""Runtime oracle for the bounded Java BigDecimal number-to-words contract."""
MAX_INPUT_LENGTH = 9
MAX_OUTPUT_BYTES = 256
_SMALL = ("Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
          "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen")
_TENS = ("", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety")
_SCALES = ("", "Thousand", "Million", "Billion", "Trillion")

def _chunk(value):
    words=[]
    if value >= 100:
        words.extend((_SMALL[value // 100], "Hundred"))
        value %= 100
    if value >= 20:
        words.append(_TENS[value // 10])
        value %= 10
    if 0 < value < 20:
        words.append(_SMALL[value])
    return words

def expected_output(values):
    if (not isinstance(values,(list,tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1,b""
    sign,whole,count=values[:3]
    if sign not in (-1,0,1) or whole < 0 or whole > 999_999_999_999_999 or count < 0 or count > 6 or len(values) != count+3:
        return -1,b""
    digits=values[3:]
    if any(d < 0 or d > 9 for d in digits):
        return -1,b""
    nonzero=whole != 0 or any(digits)
    if (nonzero and sign == 0) or (not nonzero and sign != 0):
        return -1,b""
    words=[]
    if sign < 0: words.append("Negative")
    groups=[]
    remaining=whole
    for _ in range(5):
        groups.append(remaining % 1000)
        remaining //= 1000
    for index in range(4,-1,-1):
        if groups[index]:
            words.extend(_chunk(groups[index]))
            if index: words.append(_SCALES[index])
    if not any(groups): words.append("Zero")
    if any(digits):
        words.append("Point")
        words.extend(_SMALL[d] for d in digits)
    output=" ".join(words).encode("ascii")
    return (len(output),output) if len(output) <= MAX_OUTPUT_BYTES else (-1,b"")
