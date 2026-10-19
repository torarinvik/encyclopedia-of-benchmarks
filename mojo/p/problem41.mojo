fn p41_prime(n:Int64)->Bool:
    if n<2:return False
    var d=Int64(2)
    while d<=n//d:
        if n%d==0:return False
        d+=1
    return True
fn p41_visit(inout digits:InlineArray[Int32,9],inout used:InlineArray[Bool,10],depth:Int,n:Int64,inout best:Int64):
    if depth==Int(n):
        if n>0 and p41_prime(n) and n>best:best=n
        return
    for d in range(1,Int(n+1)):
        if !used[d]:
            used[d]=True;digits[depth]=Int32(d)
            p41_visit(digits,used,depth+1,n*10+Int64(d),best)
            used[d]=False
@export("problem41")
fn problem41(n:Int64) abi("C")->Int64:
    if n<1 or n>9:return -1
    var digits=InlineArray[Int32,9](fill=0);var used=InlineArray[Bool,10](fill=False);var best=Int64(0)
    p41_visit(digits,used,0,n,best)
    return best
