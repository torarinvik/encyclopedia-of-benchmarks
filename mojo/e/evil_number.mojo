@export("evil_number")
fn evil_number(value:Int64) abi("C")->Int64:
    if value<0:return -1
    var v=UInt64(value);var ones=0
    while v>0:ones+=Int(v&1);v>>=1
    return 1 if ones%2==0 else 0
