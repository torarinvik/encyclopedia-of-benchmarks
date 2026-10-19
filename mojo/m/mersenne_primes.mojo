from std.memory import ImmutAnyOrigin, UnsafePointer
@export("mersenne_primes")
fn mersenne_primes(n:Int64) abi("C")->Int64:
    if n<2 or n>31:return -1
    if n==2:return 1
    let modulus=(Int64(1)<<Int(n))-1;var residue:Int64=4
    for _ in range(Int(n)-2):residue=(residue*residue-2)%modulus
    return 1 if residue==0 else 0
