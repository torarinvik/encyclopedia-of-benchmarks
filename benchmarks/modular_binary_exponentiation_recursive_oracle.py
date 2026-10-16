"""Oracle for recursive exponentiation by squaring with bounded integers."""
def expected_result(values):
    if not isinstance(values,(list,tuple)) or len(values)!=3 or any(type(x)is not int or not -(2**63)<=x<2**63 for x in values):return -1
    base,exponent,modulus=values
    if not 0<=base<=1_000_000 or not 0<=exponent<=60 or not 2<=modulus<=1_000_000:return -1
    if exponent==0:return 1
    def power(e):
        if e==0:return 1
        if e&1:return (power(e-1)*base)%modulus
        half=power(e//2);return (half*half)%modulus
    return power(exponent)
