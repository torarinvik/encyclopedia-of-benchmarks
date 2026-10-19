fn p119_digitsum(value_in:Int64)->Int64:
    var value=value_in;var sum=Int64(0)
    while value>0:sum+=value%10;value//=10
    return sum
@export("problem119")
fn problem119(index:Int64) abi("C")->Int64:
    if index<1 or index>30:return -1
    var values=InlineArray[Int64,10000](fill=0);var count=0
    for base in range(2,100):
        var value=Int64(base*base)
        for exponent in range(2,100):
            if p119_digitsum(value)==Int64(base):values[count]=value;count+=1
            if value>9223372036854775807//Int64(base):break
            value*=Int64(base)
    for i in range(1,count):
        let value=values[i];var j=i
        while j>0 and values[j-1]>value:values[j]=values[j-1];j-=1
        values[j]=value
    return values[Int(index-1)]
