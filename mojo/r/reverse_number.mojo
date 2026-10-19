@export("reverse_number")
fn reverse_number(value:Int64) abi("C")->Int64:
    if value<0 or value>1000000000:return -1
    var x=value;var reversed:Int64=0
    while x>0:reversed=reversed*10+x%10;x/=10
    return reversed
