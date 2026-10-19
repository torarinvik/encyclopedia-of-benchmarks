@export("number_persistence")
fn number_persistence(value:Int64) abi("C")->Int64:
    if value<0 or value>2147483647:return -1
    var x=value;var count:Int64=0
    while x>=10:
        var product:Int64=1
        while x>0:product*=x%10;x=x/10
        x=product;count+=1
    return count
