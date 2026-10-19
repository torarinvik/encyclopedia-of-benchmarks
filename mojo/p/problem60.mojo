fn p60_prime(value:Int64)->Bool:
    if value<2:return False
    if value==2 or value==3:return True
    if value%2==0 or value%3==0:return False
    var d=Int64(5)
    while d<=value//d:
        if value%d==0 or value%(d+2)==0:return False
        d+=6
    return True
fn p60_concat(left:Int64,right:Int64)->Int64:
    var scale=Int64(10)
    while scale<=right:scale*=10
    return left*scale+right
fn p60_pair(left:Int,right:Int,inout primes:InlineArray[Int32,1000],inout cache:InlineArray[UInt8,1000000])->Bool:
    let key=left*1000+right
    if cache[key]!=0:return cache[key]==2
    let reverse=right*1000+left
    if cache[reverse]!=0:return cache[reverse]==2
    let a=Int64(primes[left]);let b=Int64(primes[right])
    let works=p60_prime(p60_concat(a,b)) and p60_prime(p60_concat(b,a))
    cache[key]=2 if works else 1;cache[reverse]=cache[key]
    return works
fn p60_search(inout primes:InlineArray[Int32,1000],count:Int,inout cache:InlineArray[UInt8,1000000],inout chain:InlineArray[Int32,5],depth:Int,start:Int,sum:Int64)->Int64:
    if depth==5:return sum
    for index in range(start,count):
        var compatible=True
        for member in range(depth):
            if !p60_pair(index,Int(chain[member]),primes,cache):compatible=False;break
        if !compatible:continue
        chain[depth]=Int32(index)
        let result=p60_search(primes,count,cache,chain,depth+1,index+1,sum+Int64(primes[index]))
        if result!=0:return result
    return 0
@export("problem60")
fn problem60(placeholder:Int64) abi("C")->Int64:
    if placeholder!=0:return -1
    var primes=InlineArray[Int32,1000](fill=0);primes[0]=3;primes[1]=7;primes[2]=13;primes[3]=19;var count=4
    var cache=InlineArray[UInt8,1000000](fill=0);var chain=InlineArray[Int32,5](fill=0)
    while count<1000:
        var candidate=Int64(primes[count-1])+3
        while !p60_prime(candidate):candidate+=3
        primes[count]=Int32(candidate);count+=1
    for start in range(count):
        chain[0]=Int32(start)
        let result=p60_search(primes,count,cache,chain,1,start+1,Int64(primes[start]))
        if result!=0:return result
    return -1
