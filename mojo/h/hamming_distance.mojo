@export("hamming_distance")
def hamming_distance(left:UInt64,right:UInt64) abi("C")->Int64:
    var a=left;var b=right;var count: Int64=0
    while a!=0 or b!=0:
        if (a&1)!=(b&1):count+=1
        a>>=1;b>>=1
    return count
