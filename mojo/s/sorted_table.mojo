from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime MINKEY:Int64= -1000000
comptime MOD:Int64=1000000007
fn table_lower(a:InlineArray[Int64,256],n:Int,key:Int64)->Int:
    var l=0;var r=n
    while l<r:
        let m=l+(r-l)/2
        if a[m]<key:l=m+1
        else:r=m
    return l
fn table_upper(a:InlineArray[Int64,256],n:Int,key:Int64)->Int:
    var l=0;var r=n
    while l<r:
        let m=l+(r-l)/2
        if a[m]<=key:l=m+1
        else:r=m
    return l
fn kcode(k:Int64)->Int64:return k-MINKEY+1
fn seqcode(a:InlineArray[Int64,256],start:Int,end:Int,desc:Bool)->Int64:
    var h:Int64=0
    if desc:
        for i in range(start,end):
            let j=end-1-i+start;h=(31*h+kcode(a[j]))%MOD
    else:
        for i in range(start,end):h=(31*h+kcode(a[i]))%MOD
    return Int64(end-start)*MOD+h
@export("sorted_table_benchmark")
fn sorted_table_benchmark(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>899:return -1
    let initv=v[0]
    if initv<0 or initv>128:return -1
    let ocidx=Int(initv)+1
    if ocidx>=Int(n):return -1
    let ocv=v[ocidx]
    if ocv<0 or ocv>256 or n!=c_size_t(ocidx+1+3*ocv) or n>898:return -1
    let init=Int(initv);let ops=Int(ocv);var a=InlineArray[Int64,256](fill=0);var count=init
    for i in range(init):
        let x=v[i+1]
        if x<MINKEY or x>1000000 or (i>0 and a[i-1]>=x):return -1
        a[i]=x
    var checksum:Int64=0;let opstart=ocidx+1
    for oi in range(ops):
        let p=opstart+3*oi;let op=v[p];let x=v[p+1];let y=v[p+2];var observed:Int64=0;var add=True
        if op==0 or op==1 or op==4 or op==5 or op==7:
            if y!=0 or x<MINKEY or x>1000000:return -1
            let at=table_lower(a,count,x);let found=at<count and a[at]==x
            if op==0:observed=if found then kcode(x) else 0
            elif op==1:observed=1 if found else 0
            elif op==4:
                let nxt=if found then at+1 else at
                observed=if nxt<count then kcode(a[nxt]) else 0
            elif op==5:observed=if at>0 then kcode(a[at-1]) else 0
            else:
                if found:
                    for j in range(at,count-1):a[j]=a[j+1]
                    count-=1;observed=kcode(x)
                else:observed=0
        elif op==2 or op==3:
            if x!=0 or y!=0:return -1
            if count==0:observed=0
            elif op==2:observed=kcode(a[0])
            else:observed=kcode(a[count-1])
        elif op==6:
            if x<MINKEY or x>1000000 or (y!=0 and y!=1):return -1
            let at=table_lower(a,count,x)
            if at<count and a[at]==x:observed=kcode(x)
            else:
                if count>=256:return -1
                for j in range(count,at,-1):a[j]=a[j-1]
                a[at]=x;count+=1;observed=0
        elif op==8 or op==9:
            if x<MINKEY or x>1000000 or y<MINKEY or y>1000000:return -1
            var start=0;var end=0
            if x<=y:start=table_lower(a,count,x);end=table_upper(a,count,y)
            observed=seqcode(a,start,end,op==9)
        elif op==10 or op==11:
            if x!=0 or y!=0:return -1
            observed=seqcode(a,0,count,op==11)
        elif op==12:
            if x!=0 or y!=0:return -1
            observed=1 if count==0 else 0
        elif op==13:
            if x!=0 or y!=0:return -1
            count=0;add=False
        else:return -1
        if add:checksum+=Int64(oi+1)*(observed+1)
    for i in range(count):checksum+=Int64(ops+i+1)*kcode(a[i])
    return checksum
