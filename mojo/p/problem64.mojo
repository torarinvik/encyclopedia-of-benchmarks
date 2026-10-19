fn p64_sqrt(value:Int64)->Int64:
    var low=Int64(0);var high=value+1
    while high-low>1:
        let mid=low+(high-low)//2
        if mid<=value//mid:low=mid
        else:high=mid
    return low
fn p64_period(value:Int64,root:Int64)->Int64:
    var numerator=Int64(0);var denominator=Int64(1);var coefficient=root;var period=Int64(0)
    while True:
        numerator=denominator*coefficient-numerator
        denominator=(value-numerator*numerator)//denominator
        coefficient=(root+numerator)//denominator;period+=1
        if coefficient==2*root:break
    return period
@export("problem64")
fn problem64(inclusive_limit:Int64) abi("C")->Int64:
    if inclusive_limit<0 or inclusive_limit>10000:return -1
    var count=Int64(0)
    for value in range(2,Int(inclusive_limit+1)):
        let root=p64_sqrt(Int64(value))
        if root*root==value:continue
        if p64_period(Int64(value),root)%2==1:count+=1
    return count
