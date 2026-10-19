@export("problem123")
fn problem123(limit:Int64) abi("C")->Int64:
    if limit>10000000000:return -1
    var composite=InlineArray[Bool,300001](fill=False)
    for factor in range(2,549):
        if !composite[factor]:
            var multiple=factor*factor
            while multiple<=300000:composite[multiple]=True;multiple+=factor
    var n=Int64(1);var skip=False
    for candidate in range(2,300001):
        if composite[candidate]:continue
        if skip:skip=False;continue
        if 2*Int64(candidate)*n>limit:return n
        skip=True;n+=2
    return -1
