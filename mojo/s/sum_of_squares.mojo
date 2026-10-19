@export("sum_of_squares")
fn sum_of_squares(value:Int64) abi("C")->Int64:
    if value<0 or value>2147483647:return -1
    if value==0:return 0
    var low:Int64=1;var high=value
    while high-low>1:
        let mid=low+(high-low)/2
        if mid<=value/mid:low=mid
        else:high=mid
    let root=low
    if root*root==value:return 1
    var second=root
    for first in range(1,Int(root)+1):
        let rem=value-Int64(first)*Int64(first)
        while second*second>rem:second-=1
        if second*second==rem:return 2
    var reduced=value
    while reduced%4==0:reduced/=4
    return 4 if reduced%8==7 else 3
