@export("primorial_numbers_sequence")
fn primorial_numbers_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>15:return -1
    var product=Int64(1);var count=0;var candidate=2
    while count<Int(index):
        var prime=True;var d=2
        while d<=candidate//d:if candidate%d==0:prime=False;break;d+=1
        if prime:product*=Int64(candidate);count+=1
        candidate+=1
    return product
