fn p52_same_digits(a_in:Int64,b_in:Int64)->Bool:
    var a=a_in;var b=b_in;var ca=InlineArray[Int32,10](fill=0);var cb=InlineArray[Int32,10](fill=0)
    while a>0:ca[a%10]+=1;a//=10
    while b>0:cb[b%10]+=1;b//=10
    for i in range(10):if ca[i]!=cb[i]:return False
    return True
@export("problem52")
fn problem52(unused:Int64) abi("C")->Int64:
    if unused!=0:return -1
    var n=Int64(1)
    while True:
        var good=True
        for m in range(2,7):
            if !p52_same_digits(n,n*Int64(m)):good=False;break
        if good:return n
        n+=1
    return -1
