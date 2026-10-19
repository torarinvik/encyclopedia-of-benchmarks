from std.math import sqrt
@export("pronic_number")
fn pronic_number(n:Int64) abi("C")->Int64:
    if n<0 or n>2147483647:return -1
    let root=Int64(sqrt(Float64(n)))
    return 1 if root*(root+1)==n else 0
