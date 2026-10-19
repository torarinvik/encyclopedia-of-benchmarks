fn p86_square(value:Int64)->Bool:
    if value<0:return False
    var root=value;var next=(root+1)//2
    while next<root:root=next;next=(root+value//root)//2
    return root*root==value
@export("problem86")
fn problem86(limit:Int64) abi("C")->Int64:
    if limit>1000000:return -1
    if limit<0:return 0
    var count=Int64(0);var m=Int64(0)
    while count<=limit:
        m+=1
        for s in range(2,Int(2*m+1)):
            if !p86_square(Int64(s*s)+m*m):continue
            let high=m if m<Int64(s//2) else Int64(s//2)
            let low=Int64(s)-m if Int64(s)-m>1 else Int64(1)
            count+=high-low+1
    return m
