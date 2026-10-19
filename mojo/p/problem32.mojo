fn p32_next(inout d:InlineArray[Int32,9])->Bool:
    var pivot=7
    while pivot>=0 and d[pivot]>=d[pivot+1]:pivot-=1
    if pivot<0:return False
    var succ=8
    while d[succ]<=d[pivot]:succ-=1
    let tmp=d[pivot];d[pivot]=d[succ];d[succ]=tmp
    var left=pivot+1;var right=8
    while left<right:
        let t=d[left];d[left]=d[right];d[right]=t;left+=1;right-=1
    return True
@export("problem32")
fn problem32(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    var d=InlineArray[Int32,9](fill=0)
    for i in range(9):d[i]=Int32(i+1)
    var seen=InlineArray[Bool,10000](fill=False)
    while True:
        let product=d[5]*1000+d[6]*100+d[7]*10+d[8]
        let two=d[0]*10+d[1];let three=d[2]*100+d[3]*10+d[4]
        let four=d[1]*1000+d[2]*100+d[3]*10+d[4]
        if two*three==product:seen[product]=True
        if d[0]*four==product:seen[product]=True
        if !p32_next(d):break
    var sum=Int64(0)
    for product in range(10000):if seen[product]:sum+=Int64(product)
    return sum
