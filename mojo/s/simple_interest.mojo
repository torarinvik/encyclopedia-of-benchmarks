@export("simple_interest")
fn simple_interest(p:Float64,r:Float64,d:Float64) abi("C")->Float64:
    if p!=p or r!=r or d!=d or p<=0 or p>1000000 or r<0 or r>1 or d<=0 or d>3650:return -1.0e300
    return p*r*d
