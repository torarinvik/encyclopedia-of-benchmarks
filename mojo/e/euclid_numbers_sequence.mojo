@export("euclid_numbers_sequence")
fn euclid_numbers_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>15:return -1
    var product:Int64=1;var found=0;var candidate=2
    while found<=index:
        var prime=True
        for d in range(2,candidate):
            if d*d>candidate:break
            if candidate%d==0:prime=False;break
        if prime:product*=candidate;found+=1
        candidate+=1
    return product+1
