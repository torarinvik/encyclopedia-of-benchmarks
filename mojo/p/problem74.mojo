fn p74_fact_sum(value_in:Int64)->Int64:
    var value=value_in;var sum=Int64(0)
    while True:
        let d=value%10
        if d<2:sum+=1
        elif d==2:sum+=2
        elif d==3:sum+=6
        elif d==4:sum+=24
        elif d==5:sum+=120
        elif d==6:sum+=720
        elif d==7:sum+=5040
        elif d==8:sum+=40320
        else:sum+=362880
        value//=10
        if value<=0:break
    return sum
fn p74_chain(start:Int64,inout cache:InlineArray[UInt8,2540161])->Int:
    var path=InlineArray[Int64,128](fill=0);var plen=0;var current=start;var result=0
    while True:
        let encoded=cache[Int(current)]
        if encoded!=0:result=Int(encoded)-1;break
        let next=p74_fact_sum(current);var repeats=False
        for i in range(plen):if path[i]==next:repeats=True;break
        if repeats:cache[Int(current)]=1;result=0;break
        path[plen]=current;plen+=1;current=next
    while plen>0:
        plen-=1;current=path[plen];result+=1;cache[Int(current)]=UInt8(result+1)
    return Int(cache[Int(start)])-1
@export("problem74")
fn problem74(num_terms:Int64,max_start:Int64) abi("C")->Int64:
    if max_start>1000000:return -1
    if max_start<=1:return 0
    var cache=InlineArray[UInt8,2540161](fill=0)
    cache[145]=1;cache[169]=4;cache[36301]=4;cache[1454]=4;cache[871]=3;cache[45361]=3;cache[872]=3
    var count=Int64(0)
    for start in range(1,Int(max_start)):
        if Int64(p74_chain(Int64(start),cache))==num_terms:count+=1
    return count
