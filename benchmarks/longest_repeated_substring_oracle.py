"""Reference for longest repeated substring length."""
MAX_INPUT_LENGTH=128
MAX_SEQUENCE_LENGTH=127
def expected_result(values):
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH:return -1
    n=values[0]
    if type(n)is not int or not 0<=n<=MAX_SEQUENCE_LENGTH or len(values)!=n+1:return -1
    s=values[1:]
    if any(type(x)is not int or not 0<=x<=127 for x in s):return -1
    best=0
    for i in range(n):
        for j in range(i+1,n):
            k=0
            while i+k<n and j+k<n and s[i+k]==s[j+k]:k+=1
            if k>best:best=k
    return best
