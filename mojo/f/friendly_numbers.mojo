fn fnums_index(n:UInt64)->Float64:
    var total=n;var d:UInt64=1
    while d*2<n:
        if n%d==0:total+=d
        d+=1
    return Float64(total)/Float64(n)

@export("friendly_numbers")
fn friendly_numbers(a:UInt64,b:UInt64) abi("C")->Int64:
    if a==0 or b==0 or a==b or a>1000 or b>1000:return -1
    return 1 if fnums_index(a)==fnums_index(b) else 0
