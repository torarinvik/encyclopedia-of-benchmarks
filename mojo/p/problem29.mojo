@export("problem29")
fn problem29(limit:Int64) abi("C")->Int64:
    if limit<1 or limit>100:return -1
    if limit==1:return 0
    var roots=InlineArray[Int32,101](fill=0);var exponents=InlineArray[Int32,101](fill=0);var seen=InlineArray[Bool,60701](fill=False);var distinct=Int64(0)
    for a in range(2,Int(limit+1)):
        roots[a]=Int32(a);exponents[a]=1
        for e in range(2,7):
            for r in range(2,a+1):
                var power=1
                for _ in range(e):power*=r;if power>a:break
                if power==a and e>exponents[a]:roots[a]=Int32(r);exponents[a]=Int32(e)
        for b in range(2,Int(limit+1)):
            let key=Int(roots[a])*601+Int(exponents[a])*b
            if !seen[key]:seen[key]=True;distinct+=1
    return distinct
