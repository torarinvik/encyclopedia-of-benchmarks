@export("index_of_right_most_set_bit")
fn index_of_right_most_set_bit(value:Int64) abi("C")->Int64:
    if value< -2147483648 or value>2147483647 or value==0:return -1
    var magnitude=UInt64(-value if value<0 else value)
    var index:Int64=0
    while (magnitude&1)==0:magnitude>>=1;index+=1
    return index
