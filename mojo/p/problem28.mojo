@export("problem28")
fn problem28(size:Int64) abi("C")->Int64:
    if size<0 or size>100000:return -1
    var total=Int64(1);let layers=(size+1)//2
    for layer in range(1,Int(layers)):
        let odd=2*Int64(layer)+1;let even=2*Int64(layer)
        total+=4*odd*odd-6*even
    return total
