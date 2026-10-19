@export("problem2")
fn problem2(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>4000000:return -1
    var previous=Int64(1);var current=Int64(2);var sum=Int64(0)
    while current<limit:
        if current%2==0:sum+=current
        let next=previous+current;previous=current;current=next
    return sum
