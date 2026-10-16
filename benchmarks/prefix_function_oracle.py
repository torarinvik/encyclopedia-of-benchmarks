"""Runtime oracle for the bounded ASCII prefix-function benchmark."""
import struct
MAX_INPUT_LENGTH=4097
MAX_TEXT_LENGTH=4096
def expected_output(values):
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH or any(type(x)is not int or not -(2**63)<=x<2**63 for x in values):return -1,b""
    n=values[0]
    if not 0<=n<=MAX_TEXT_LENGTH or len(values)!=n+1:return -1,b""
    text=values[1:]
    if any(not 0<=c<=127 for c in text):return -1,b""
    pi=[0]*n
    for i in range(1,n):
        j=pi[i-1]
        while j>0 and text[i]!=text[j]:j=pi[j-1]
        if text[i]==text[j]:j+=1
        pi[i]=j
    return 4*n,b"".join(struct.pack('<i',x) for x in pi)
