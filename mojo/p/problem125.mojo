fn p125_palindrome(value_in:Int64)->Bool:
    if value_in%10==0:return False
    var value=value_in;var rev=Int64(0)
    while value>0:rev=rev*10+value%10;value//=10
    return rev==value_in
@export("problem125")
fn problem125(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>100000000:return -1
    var seen=InlineArray[Int64,32768](fill=0);var total=Int64(0)
    for first in range(1,10000):
        var last=first+1;var sum=Int64(first*first+last*last)
        if sum>=limit:break
        while sum<limit:
            if p125_palindrome(sum):
                var slot=Int(sum%32768)
                while seen[slot]!=0 and seen[slot]!=sum:slot=(slot+1)%32768
                if seen[slot]==0:seen[slot]=sum;total+=sum
            last+=1;sum+=Int64(last*last)
    return total
