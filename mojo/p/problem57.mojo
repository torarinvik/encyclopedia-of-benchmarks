@export("problem57")
fn problem57(iterations:Int64) abi("C")->Int64:
    if iterations<=0:return 0
    if iterations>10000:return -1
    var num=InlineArray[UInt64,512](fill=0);var den=InlineArray[UInt64,512](fill=0);var nn=InlineArray[UInt64,512](fill=0);var nd=InlineArray[UInt64,512](fill=0)
    num[0]=1;den[0]=1;var nl=1;var dl=1;var result=Int64(0);let base=UInt64(1000000000)
    for _ in range(Int(iterations)):
        let width=nl if nl>dl else dl;var nc=UInt64(0);var dc=UInt64(0)
        for i in range(width):
            let x=num[i] if i<nl else UInt64(0);let y=den[i] if i<dl else UInt64(0)
            let ns=x+2*y+nc;let ds=x+y+dc;nn[i]=ns%base;nd[i]=ds%base;nc=ns//base;dc=ds//base
        var nlen=width;var dlen=width
        while nc>0:if nlen>=512:return -1;nn[nlen]=nc%base;nlen+=1;nc//=base
        while dc>0:if dlen>=512:return -1;nd[dlen]=dc%base;dlen+=1;dc//=base
        var ndigits=(nlen-1)*9;var top=nn[nlen-1];ndigits+=1;while top>=10:ndigits+=1;top//=10
        var ddigits=(dlen-1)*9;top=nd[dlen-1];ddigits+=1;while top>=10:ddigits+=1;top//=10
        if ndigits>ddigits:result+=1
        for i in range(nlen):num[i]=nn[i]
        for i in range(dlen):den[i]=nd[i]
        nl=nlen;dl=dlen
    return result
