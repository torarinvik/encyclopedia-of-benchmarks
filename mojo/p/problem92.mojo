fn p92_sqsum(v_in:Int)->Int:
    var v=v_in;var total=0
    while v!=0:let d=v%10;total+=d*d;v//=10
    return total
fn p92_reaches89(v_in:Int)->Bool:
    var v=v_in
    while v!=1 and v!=89:v=p92_sqsum(v)
    return v==89
@export("problem92")
fn problem92(number:Int64) abi("C")->Int64:
    if number<0 or number>10000000:return -1
    var digits=InlineArray[Int32,7](fill=0);var count=0
    if number>1:
        var remaining=Int(number-1);var reversed=InlineArray[Int32,7](fill=0)
        while remaining!=0:reversed[count]=Int32(remaining%10);count+=1;remaining//=10
        for i in range(count):digits[i]=reversed[count-i-1]
    else:digits[0]=0;count=1
    let limit=count*81+1
    var tight=InlineArray[Int64,568](fill=0);var free=InlineArray[Int64,568](fill=0);var nt=InlineArray[Int64,568](fill=0);var nf=InlineArray[Int64,568](fill=0);tight[0]=1
    for pos in range(count):
        for i in range(568):nt[i]=0;nf[i]=0
        let bound=Int(digits[pos])
        for sum in range(limit):
            if tight[sum]!=0:
                for digit in range(bound+1):
                    let next=sum+digit*digit
                    if next>=limit:continue
                    if digit==bound:nt[next]+=tight[sum]
                    else:nf[next]+=tight[sum]
            if free[sum]!=0:
                for digit in range(10):
                    let next=sum+digit*digit
                    if next<limit:nf[next]+=free[sum]
        for i in range(568):tight[i]=nt[i];free[i]=nf[i]
    var result=Int64(0)
    for sum in range(1,limit):if p92_reaches89(sum):result+=tight[sum]+free[sum]
    return result
