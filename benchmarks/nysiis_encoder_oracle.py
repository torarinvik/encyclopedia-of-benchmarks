"""Independent NYSIIS encoder oracle over bounded ASCII-name inputs."""
MAX_INPUT_LENGTH = 65
MAX_TEXT_LENGTH = 64
MAX_OUTPUT_BYTES = 64

def expected_output(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return -1, b""
    if any(not 65 <= x <= 90 and not 97 <= x <= 122 for x in values[1:]):
        return -1, b""
    s = ''.join(chr(x).upper() for x in values[1:])
    def replace_at(i, old, new):
        nonlocal s
        s = s[:i] + new + s[i + len(old):]
    for old, new in (("MAC","MCC"),("KN","NN"),("K","C"),("PH","FF"),("PF","FF"),("SCH","SSS")):
        if s.startswith(old): replace_at(0, old, new); break
    for old, new in (("EE","Y"),("IE","Y"),("DT","D"),("RT","D"),("NT","D"),("ND","D")):
        if s.endswith(old): replace_at(len(s)-len(old), old, new); break
    rules = (("EV","AF"),("E","A"),("I","A"),("O","A"),("U","A"),("Q","G"),("Z","S"),("M","N"),("KN","NN"),("K","C"),("SCH","SSS"),("PH","FF"))
    i = 1
    while i < len(s):
        for old, new in rules:
            if s.startswith(old, i): replace_at(i, old, new); break
        else:
            c = s[i]
            if c == 'H' and (s[i-1] not in 'AEIOU' or (i+1 < len(s) and s[i+1] not in 'AEIOU')):
                replace_at(i, c, s[i-1])
            elif c == 'W' and s[i-1] in 'AEIOU':
                replace_at(i, c, s[i-1])
        i += 1
    compact = []
    for c in s:
        if not compact or c != compact[-1]: compact.append(c)
    s = ''.join(compact)
    if s.endswith('S'): s = s[:-1]
    elif s.endswith('AY'): s = s[:-2] + 'Y'
    elif s.endswith('A'): s = s[:-1]
    out = s.encode('ascii')
    return (len(out), out) if len(out) <= MAX_OUTPUT_BYTES else (-1, b"")
