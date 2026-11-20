from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn soc_shortest_path(adjacency:InlineArray[Int64,8],n:Int,source:Int,target:Int)->InlineArray[Int64,9]:
    var result=InlineArray[Int64,9](fill=0)
    var distance=InlineArray[Int,8](fill=-1)
    var predecessor=InlineArray[Int,8](fill=-1)
    var queue=InlineArray[Int,8](fill=0)
    var head=0
    var tail=1
    queue[0]=source
    distance[source]=0
    while head<tail:
        let vertex=queue[head]
        head+=1
        for successor in range(n):
            let bit=Int64(1)<<successor
            if adjacency[vertex]&bit!=0 and distance[successor]==-1:
                distance[successor]=distance[vertex]+1
                predecessor[successor]=vertex
                queue[tail]=successor
                tail+=1
    if distance[target]==-1:return result
    var reversed=InlineArray[Int,8](fill=0)
    var count=0
    var vertex=target
    while True:
        reversed[count]=vertex
        count+=1
        if vertex==source:break
        vertex=predecessor[vertex]
        if vertex<0:return result
    result[0]=count
    for index in range(count):result[index+1]=reversed[count-index-1]
    return result

fn soc_gcd(left_value:Int64,right_value:Int64)->Int64:
    var left=left_value
    var right=right_value
    while right!=0:
        let remainder=left%right
        left=right
        right=remainder
    return left

@export("network_erosion_strength_of_connection")
fn network_erosion_strength_of_connection(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>117:return -1
    let vertex_raw=input[0]
    let edge_raw=input[1]
    let source_raw=input[2]
    let target_raw=input[3]
    if vertex_raw<2 or vertex_raw>8 or edge_raw<0 or edge_raw>vertex_raw*(vertex_raw-1) or source_raw<0 or source_raw>=vertex_raw or target_raw<0 or target_raw>=vertex_raw or source_raw==target_raw:return -1
    let n=Int(vertex_raw)
    let edge_count=Int(edge_raw)
    let source=Int(source_raw)
    let target=Int(target_raw)
    if length!=c_size_t(4+2*edge_count):return -1
    var adjacency=InlineArray[Int64,8](fill=0)
    var cursor=4
    for _ in range(edge_count):
        let from_raw=input[cursor]
        let to_raw=input[cursor+1]
        cursor+=2
        if from_raw<0 or from_raw>=vertex_raw or to_raw<0 or to_raw>=vertex_raw or from_raw==to_raw:return -1
        let from=Int(from_raw)
        let to=Int(to_raw)
        let bit=Int64(1)<<to
        if adjacency[from]&bit!=0:return -1
        adjacency[from]|=bit
    var distances=InlineArray[Int,8](fill=-1)
    let first=soc_shortest_path(adjacency,n,source,target)
    if first[0]!=0:
        let initial_length=Int(first[0])-1
        distances[source]=initial_length
        distances[target]=initial_length
        while True:
            let current=soc_shortest_path(adjacency,n,source,target)
            let path_count=Int(current[0])
            if path_count==0:break
            let path_length=path_count-1
            if path_length==1:
                adjacency[source]&=~(Int64(1)<<target)
                continue
            for index in range(path_count):
                let vertex=Int(current[index+1])
                if distances[vertex]==-1:distances[vertex]=path_length
            for index in range(1,path_count-1):
                let vertex=Int(current[index+1])
                let bit=Int64(1)<<vertex
                adjacency[vertex]=0
                for other in range(n):adjacency[other]&=~bit
    var reciprocal_sum_scaled:Int64=0
    for vertex in range(n):
        if distances[vertex]>=1:reciprocal_sum_scaled+=420//distances[vertex]
    var numerator:Int64=2*reciprocal_sum_scaled
    var denominator:Int64=420*(n+2)
    if numerator==0:denominator=1
    else:
        let divisor=soc_gcd(numerator,denominator)
        numerator//=divisor
        denominator//=divisor
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<16:return -2
    let numerator_bits=UInt64(numerator)
    let denominator_bits=UInt64(denominator)
    for byte in range(8):
        output[byte]=UInt8((numerator_bits>>UInt64(8*byte))&255)
        output[8+byte]=UInt8((denominator_bits>>UInt64(8*byte))&255)
    return 16
