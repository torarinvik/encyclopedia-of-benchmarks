@export("kummer_numbers_sequence")
fn kummer_numbers_sequence(idx:Int64) abi("C")->Int64:
    if idx<0 or idx>14:return -1
    var product:Int64=1;var found=0;var candidate=2
    while found<=Int(idx):
        var prime=True
        for d in range(2,candidate):if candidate%d==0:prime=False;break
        if prime:product*=candidate;found+=1
        candidate+=1
    return product-1
