fn p203_squarefree(value_in:Int64)->Bool:
    var value=value_in;var factor=Int64(2)
    while factor<=value//factor:
        if value%(factor*factor)==0:return False
        while value%factor==0:value//=factor
        factor+=1
    return True
@export("problem203")
fn problem203(depth:Int64) abi("C")->Int64:
    if depth>51:return -1
    var row=InlineArray[Int64,52](fill=0);var next=InlineArray[Int64,52](fill=0);row[0]=1;var values=InlineArray[Int64,1400](fill=0);var count=1;values[0]=1
    for r in range(2,Int(depth+1)):
        next[0]=1;next[r-1]=1
        for c in range(1,r-1):next[c]=row[c-1]+row[c]
        for c in range(r):values[count]=next[c];count+=1
        for c in range(r):row[c]=next[c]
    for i in range(1,count):
        let v=values[i];var j=i
        while j>0 and values[j-1]>v:values[j]=values[j-1];j-=1
        values[j]=v
    var total=Int64(0);var prev=Int64(-1)
    for i in range(count):
        let value=values[i]
        if value!=prev and p203_squarefree(value):total+=value
        prev=value
    return total
