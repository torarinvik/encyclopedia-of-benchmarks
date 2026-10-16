"""Oracle for a deterministic bounded subset of the pinned Enigma machine."""
MAX_TEXT = 12
MAX_INPUT_LENGTH = 4 + MAX_TEXT
INVALID = -1
ABC = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
ROTORS = ("EGZWVONAHDCLFQMSIPJBYUKXTR", "FOBHMDKEXQNRAULPGSJVTYICZW", "ZJXESIUQLHAVRMDOYGTNFWPBKC")
REFLECTOR = "NOPQRSTUVWXYZABCDEFGHIJKLM"

def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return INVALID
    length, p1, p2, p3 = values[:4]
    if not 0 <= length <= MAX_TEXT or len(values) != 4 + length or any(not 1 <= p <= 26 for p in (p1,p2,p3)):
        return INVALID
    if any(not 0 <= x < 26 for x in values[4:]):
        return INVALID
    positions=[p1-1,p2-1,p3-1]
    result=0
    for letter in values[4:]:
        symbol=ABC[letter]
        for rotor,pos in zip(ROTORS,positions):
            symbol=rotor[(ABC.index(symbol)+pos)%26]
        symbol=REFLECTOR[ABC.index(symbol)]
        for rotor,pos in zip(reversed(ROTORS),reversed(positions)):
            symbol=ABC[(rotor.index(symbol)-pos)%26]
        result=result*26+ABC.index(symbol)
        positions[0]+=1
        if positions[0]>=26:
            positions[0]=0; positions[1]+=1
            if positions[1]>=26:
                positions[1]=0; positions[2]=(positions[2]+1)%26
    return result
