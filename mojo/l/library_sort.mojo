from std.ffi import c_size_t
from std.memory import MutAnyOrigin,UnsafePointer
fn lib_find(data:InlineArray[Int64,512],used:InlineArray[Int64,512],cap:Int,value:Int64)->Int:
    var low=0;var high=cap
    while low<high:
        let middle=low+(high-low)/2;var probe=2147483647
        for i in range(middle,cap):
            if used[i]!=0:probe=Int(data[i]);break
        if probe!=2147483647 and Int64(probe)<=value:low=middle+1
        else:high=middle
    return low
fn lib_insert_end(mut data:InlineArray[Int64,512],mut used:InlineArray[Int64,512],cap:Int,value:Int64):
    let last=cap-1;var left=last-1
    while left>=0 and used[left]!=0:left-=1
    if left<0:return
    for i in range(left,last):data[i]=data[i+1]
    used[left]=1;data[last]=value
fn lib_insert(mut data:InlineArray[Int64,512],mut used:InlineArray[Int64,512],cap:Int,value:Int64):
    let pos=lib_find(data,used,cap,value)
    if pos>=cap:lib_insert_end(data,used,cap,value);return
    if used[pos]==0:data[pos]=value;used[pos]=1;return
    var right=pos
    while right<cap and used[right]!=0:right+=1
    var left=pos-1
    while left>=0 and used[left]!=0:left-=1
    let can_right=right<cap;let can_left=left>=0
    if can_right and (not can_left or right-pos<=pos-left):
        var i=right
        while i>pos:data[i]=data[i-1];i-=1
        used[right]=1;data[pos]=value
    elif can_left:
        for i in range(left,pos-1):data[i]=data[i+1]
        used[left]=1;data[pos-1]=value
@export("library_sort")
fn library_sort(values:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if n<2 or n>256 or values==UnsafePointer[Int64,MutAnyOrigin]():return
    let cap=2*Int(n);var data=InlineArray[Int64,512](fill=0);var occupied=InlineArray[Int64,512](fill=0);var temp=InlineArray[Int64,256](fill=0)
    var filled=1;var next=1;var round=0;let middle=cap/2;data[middle]=values[0];occupied[middle]=1
    while next<Int(n):
        var batch=1<<round
        if batch>Int(n)-next:batch=Int(n)-next
        for j in range(batch):lib_insert(data,occupied,cap,values[next+j]);filled+=1
        next+=batch;round+=1
        if next<Int(n):
            var at=0
            for i in range(cap):
                if occupied[i]!=0:temp[at]=data[i];at+=1
            for i in range(cap):occupied[i]=0
            for i in range(filled):
                let slot=i*cap/filled;data[slot]=temp[i];occupied[slot]=1
    var output=0
    for i in range(cap):
        if occupied[i]!=0:values[output]=data[i];output+=1
