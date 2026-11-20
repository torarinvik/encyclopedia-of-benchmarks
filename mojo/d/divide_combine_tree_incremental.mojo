from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 16
comptime MAX_NODES = 31
comptime TREE_SIZE = 68

fn dct_add(node:Int,left:Int,right:Int,ql:Int,qr:Int,delta:Int,
    inout minimum:InlineArray[Int,TREE_SIZE],inout lazy:InlineArray[Int,TREE_SIZE]):
    if ql<=left and right<=qr:
        minimum[node]+=delta;lazy[node]+=delta
        return
    let middle=(left+right)/2
    if lazy[node]!=0:
        let tag=lazy[node]
        minimum[node*2]+=tag;minimum[node*2+1]+=tag
        lazy[node*2]+=tag;lazy[node*2+1]+=tag;lazy[node]=0
    if ql<=middle and qr>=left:dct_add(node*2,left,middle,ql,qr,delta,minimum,lazy)
    if qr>middle and ql<=right:dct_add(node*2+1,middle+1,right,ql,qr,delta,minimum,lazy)
    minimum[node]=minimum[node*2] if minimum[node*2]<minimum[node*2+1] else minimum[node*2+1]

fn dct_first_zero(node:Int,left:Int,right:Int,minimum:InlineArray[Int,TREE_SIZE])->Int:
    if left==right:return left
    let middle=(left+right)/2
    if minimum[node*2]==0:return dct_first_zero(node*2,left,middle,minimum)
    return dct_first_zero(node*2+1,middle+1,right,minimum)

fn dct_connected(left:Int,right:Int,logs:InlineArray[Int,MAX_N+1],
    range_min:InlineArray[Int,MAX_N*MAX_N],range_max:InlineArray[Int,MAX_N*MAX_N])->Bool:
    let level=logs[right-left+1];let span=1<<level;let other=right+1-span
    let low_a=range_min[level*MAX_N+left];let low_b=range_min[level*MAX_N+other]
    let high_a=range_max[level*MAX_N+left];let high_b=range_max[level*MAX_N+other]
    let low=low_a if low_a<low_b else low_b
    let high=high_a if high_a>high_b else high_b
    return high-low==right-left

fn dct_new_node(left:Int,right:Int,combine:Int,last_left:Int,
    inout count:Int,inout node_left:InlineArray[Int,MAX_NODES],
    inout node_right:InlineArray[Int,MAX_NODES],inout node_combine:InlineArray[Int,MAX_NODES],
    inout node_last:InlineArray[Int,MAX_NODES])->Int:
    let id=count;count+=1
    node_left[id]=left;node_right[id]=right;node_combine[id]=combine;node_last[id]=last_left
    return id

@export("divide_combine_tree_incremental")
fn divide_combine_tree_incremental(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>c_size_t(MAX_N+2):return -1
    let n_value=input[0]
    if n_value<1 or n_value>Int64(MAX_N) or length!=c_size_t(n_value+1):return -1
    let n=Int(n_value)
    var permutation=InlineArray[Int,MAX_N](fill=0);var seen=InlineArray[Int,MAX_N](fill=0)
    for i in range(n):
        let value=input[i+1]
        if value<0 or value>=n_value or seen[Int(value)]!=0:return -1
        permutation[i]=Int(value);seen[Int(value)]=1
    var logs=InlineArray[Int,MAX_N+1](fill=0)
    for i in range(2,n+1):logs[i]=logs[i/2]+1
    let levels=logs[n]+1
    var range_min=InlineArray[Int,MAX_N*MAX_N](fill=0)
    var range_max=InlineArray[Int,MAX_N*MAX_N](fill=0)
    for i in range(n):range_min[i]=permutation[i];range_max[i]=permutation[i]
    for level in range(1,levels):
        let half=1<<(level-1);let width=half*2
        for start in range(0,n-width+1):
            let low_a=range_min[(level-1)*MAX_N+start];let low_b=range_min[(level-1)*MAX_N+start+half]
            range_min[level*MAX_N+start]=low_a if low_a<low_b else low_b
            let high_a=range_max[(level-1)*MAX_N+start];let high_b=range_max[(level-1)*MAX_N+start+half]
            range_max[level*MAX_N+start]=high_a if high_a>high_b else high_b

    var segment_min=InlineArray[Int,TREE_SIZE](fill=0);var lazy=InlineArray[Int,TREE_SIZE](fill=0)
    var node_left=InlineArray[Int,MAX_NODES](fill=0);var node_right=InlineArray[Int,MAX_NODES](fill=0)
    var node_combine=InlineArray[Int,MAX_NODES](fill=0);var node_last=InlineArray[Int,MAX_NODES](fill=0)
    var node_stack=InlineArray[Int,MAX_N](fill=0);var min_stack=InlineArray[Int,MAX_N](fill=0)
    var max_stack=InlineArray[Int,MAX_N](fill=0)
    var node_top=0;var min_top=0;var max_top=0;var node_count=0
    for end in range(n):
        let value=permutation[end]
        while min_top>0 and permutation[min_stack[min_top-1]]>=value:
            min_top-=1;let position=min_stack[min_top]
            let start=min_stack[min_top-1]+1 if min_top>0 else 0
            dct_add(1,0,n-1,start,position,permutation[position],segment_min,lazy)
        while max_top>0 and permutation[max_stack[max_top-1]]<=value:
            max_top-=1;let position=max_stack[max_top]
            let start=max_stack[max_top-1]+1 if max_top>0 else 0
            dct_add(1,0,n-1,start,position,-permutation[position],segment_min,lazy)
        var start=min_stack[min_top-1]+1 if min_top>0 else 0
        dct_add(1,0,n-1,start,end,-value,segment_min,lazy);min_stack[min_top]=end;min_top+=1
        start=max_stack[max_top-1]+1 if max_top>0 else 0
        dct_add(1,0,n-1,start,end,value,segment_min,lazy);max_stack[max_top]=end;max_top+=1
        let leftmost=dct_first_zero(1,0,n-1,segment_min)
        var current=dct_new_node(end,end,0,0,node_count,node_left,node_right,node_combine,node_last)
        while node_top>0 and node_left[node_stack[node_top-1]]>=leftmost:
            let top=node_stack[node_top-1]
            if node_combine[top]!=0 and dct_connected(node_last[top],end,logs,range_min,range_max):
                node_right[top]=end;node_last[top]=node_left[current];node_top-=1;current=node_stack[node_top]
            elif dct_connected(node_left[top],end,logs,range_min,range_max):
                let merged=dct_new_node(node_left[top],end,1,node_left[current],node_count,node_left,node_right,node_combine,node_last)
                node_top-=1;current=merged
            else:
                let merged=dct_new_node(-1,end,0,0,node_count,node_left,node_right,node_combine,node_last)
                node_top-=1
                while node_top>0 and not dct_connected(node_left[node_stack[node_top-1]],end,logs,range_min,range_max):node_top-=1
                if node_top==0:return -1
                node_top-=1;let base=node_stack[node_top];node_left[merged]=node_left[base];current=merged
        node_stack[node_top]=current;node_top+=1
        dct_add(1,0,n-1,0,end,-1,segment_min,lazy)
    for i in range(1,node_count):
        let left=node_left[i];let right=node_right[i];var j=i
        while j>0 and (node_left[j-1]>left or (node_left[j-1]==left and node_right[j-1]>right)):
            node_left[j]=node_left[j-1];node_right[j]=node_right[j-1];j-=1
        node_left[j]=left;node_right[j]=right
    var checksum:Int64=0
    for i in range(node_count):
        checksum+=Int64(i+1)*(Int64(node_left[i]+1)*Int64(n+1)+Int64(node_right[i]+1))
    return checksum
