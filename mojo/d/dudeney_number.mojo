@export("dudeney_number")
fn dudeney_number(number:Int64) abi("C")->Int64:
    if number<=0 or number>2147483647:return -1
    var low:Int64=1;var high:Int64=1290;var root:Int64=0
    while low<=high:
        let mid=low+(high-low)/2;let cube=mid*mid*mid
        if cube==number:root=mid;break
        if cube<number:low=mid+1
        else:high=mid-1
    if root==0:return 0
    var remaining=number;var sum:Int64=0
    while remaining>0:sum+=remaining%10;remaining/=10
    return 1 if sum==root else 0
