@export("perfect_number")
fn perfect_number(n:Int64) abi("C")->Int64:
    if n<=1:return 0
    if n>1000000000000:return -1
    var sum:Int64=1;var f:Int64=2
    while f<=n/f:
        if n%f==0:sum+=f;let p=n/f;if p!=f:sum+=p;if sum>n:return 0
        f+=1
    return 1 if sum==n else 0
