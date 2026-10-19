@export("problem94")
fn problem94(max_perimeter:Int64) abi("C")->Int64:
    if max_perimeter<0 or max_perimeter>1000000000:return -1
    var previous=Int64(1);var value=Int64(2);var total=Int64(0);var index=Int64(0);var perimeter=Int64(0)
    while perimeter<=max_perimeter:
        total+=perimeter;previous+=2*value;value+=previous
        perimeter=2*value+2 if index%2==0 else 2*value-2;index+=1
    return total
