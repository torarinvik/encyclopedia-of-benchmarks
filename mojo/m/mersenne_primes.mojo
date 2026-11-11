@export("mersenne_primes")
def mersenne_primes(n:Int64) abi("C")->Int64:
    if n<2 or n>31:return -1
    if n==2:return 1
    var modulus=(Int64(1)<<n)-1;var residue:Int64=4
    for _ in range(Int(n)-2):residue=(residue*residue-2)%modulus
    return 1 if residue==0 else 0
