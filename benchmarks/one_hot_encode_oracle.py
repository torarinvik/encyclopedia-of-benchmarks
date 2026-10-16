"""Runtime oracle for one categorical column encoded as a one-hot matrix."""
MAX_INPUT_LENGTH = 33
MAX_OUTPUT_BYTES = 832

def expected_output(values):
    if (not isinstance(values,(list,tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1,b""
    rows=values[0]
    if type(rows) is not int or not 1 <= rows <= 32 or len(values) != rows+1:
        return -1,b""
    labels=values[1:]
    if any(label<0 or label>25 for label in labels):return -1,b""
    levels=sorted(set(labels))
    col={value:index for index,value in enumerate(levels)}
    output=bytes(1 if col[label]==c else 0 for label in labels for c in range(len(levels)))
    return len(output),output
