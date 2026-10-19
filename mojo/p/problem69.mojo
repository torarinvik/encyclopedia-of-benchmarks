@export("problem69")
fn problem69(inclusive_limit:Int64) abi("C")->Int64:
    if inclusive_limit<1 or inclusive_limit>1000000:return -1
    let limit=Int(inclusive_limit);var phi=InlineArray[Int32,1000001](fill=0)
    for i in range(limit+1):phi[i]=Int32(i)
    for n in range(2,limit+1):
        if phi[n]!=Int32(n):continue
        phi[n]-=1
        var m=n*2
        while m<=limit:phi[m]=(phi[m]//Int32(n))*Int32(n-1);m+=n
    var answer=1
    for n in range(1,limit+1):
        if Int64(n)*Int64(phi[answer])>Int64(answer)*Int64(phi[n]):answer=n
    return Int64(answer)
