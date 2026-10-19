fn p74s_fact_sum(value_in:Int64)->Int64:
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
@export("problem74_sol2")
fn problem74_sol2(chain_length:Int64,number_limit:Int64) abi("C")->Int64:
    if chain_length<1 or chain_length>60 or number_limit<1 or number_limit>1000000:return -1
    if number_limit==1:return 0
    var cache=InlineArray[Int32,1000000](fill=0);var count=Int64(0)
    for start in range(1,Int(number_limit)):
        var path=InlineArray[Int64,61](fill=0);var plen=0;var steps=Int64(0);var current=Int64(start)
        while !(current>=1 and current<number_limit and cache[Int(current)]!=0) and steps<=chain_length:
            var repeated=False
            for i in range(plen):if path[i]==current:repeated=True;break
            if repeated:break
            path[plen]=current;plen+=1;steps+=1;current=p74s_fact_sum(current)
        if current>=1 and current<number_limit and cache[Int(current)]!=0:steps+=Int64(cache[Int(current)])
        cache[start]=Int32(steps)
        if steps==chain_length:count+=1
    return count
