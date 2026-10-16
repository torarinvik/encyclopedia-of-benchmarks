"""Runtime oracle for the bounded greedy graph nearest-neighbour walk."""
MAX_INPUT_LENGTH = 257
MAX_OUTPUT_BYTES = 47

def expected_output(values):
    if (not isinstance(values,(list,tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1,b""
    count=values[0]
    if type(count) is not int or not 1 <= count <= 16 or len(values) != 1+count*count:
        return -1,b""
    weights=values[1:]
    if any(w<0 or w>1_000_000 for w in weights):return -1,b""
    seen=[False]*count
    path=[]
    current=0
    for step in range(count):
        path.append(current);seen[current]=True
        if step+1<count:
            best=None;distance=0
            for candidate in range(count):
                if not seen[candidate]:
                    d=weights[current*count+candidate]
                    if best is None or d<distance:best=candidate;distance=d
            current=best
    output=','.join(map(str,path)).encode('ascii')
    return len(output),output
