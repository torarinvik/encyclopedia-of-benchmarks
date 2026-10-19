fn p4_pal(value_in:Int64)->Bool:
    var value=value_in;var rev=Int64(0)
    while value>0:rev=rev*10+value%10;value//=10
    return rev==value_in
@export("problem4")
fn problem4(digits:Int64) abi("C")->Int64:
    if digits<1 or digits>3:return -1
    let minimum=Int64(1 if digits==1 else (10 if digits==2 else 100))
    let maximum=Int64(9 if digits==1 else (99 if digits==2 else 999));var largest=Int64(0)
    var first=maximum
    while first>=minimum and first*maximum>largest:
        var second=maximum
        while second>=first and first*second>largest:
            let product=first*second
            if p4_pal(product):largest=product
            second-=1
        first-=1
    return largest
