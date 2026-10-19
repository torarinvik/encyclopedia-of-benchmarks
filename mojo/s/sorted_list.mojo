from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn sorted_list_pos(a:InlineArray[Int64,256],count:Int,target:Int64)->(Int,Bool):
    var lo=0;var hi=count
    while hi>lo:
        let mid=(lo+hi)/2
        if target>a[mid]:lo=mid+1
        elif target<a[mid]:hi=mid
        else:return (mid,True)
    return (lo,False)
@export("sorted_list_benchmark")
fn sorted_list_benchmark(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]():
        if n==0:return 0
        return -1
    if n>1025 or n%2!=0 or n>1024:return -1
    let ops=Int(n)/2
    if ops>512:return -1
    var a=InlineArray[Int64,256](fill=0);var count=0;var checksum:Int64=0
    for opi in range(ops):
        let op=v[2*opi];let x=v[2*opi+1]
        if op<0 or op>5:return -1
        if op==0:
            if x<0 or x>1000000 or count>=256:return -1
            let (pos,_)=sorted_list_pos(a,count,x)
            for j in range(count,pos,-1):a[j]=a[j-1]
            a[pos]=x;count+=1
        elif op==1 or op==2:
            if x<0 or x>1000000:return -1
            let (pos,found)=sorted_list_pos(a,count,x);let obs=1 if found else 0
            if op==2 and found:
                for j in range(pos,count-1):a[j]=a[j+1]
                count-=1
            checksum+=Int64(opi+1)*Int64(obs+1000000)
        elif op==3:
            if x!=0:return -1
            checksum+=Int64(opi+1)*Int64(count+1000000)
        elif op==4:
            if x<0 or x>=count:return -1
            checksum+=Int64(opi+1)*(a[Int(x)]+1000000)
        else:
            if x!=0:return -1
            count=0
    for i in range(count):checksum+=Int64(ops+i+1)*(a[i]+1000000)
    return checksum
