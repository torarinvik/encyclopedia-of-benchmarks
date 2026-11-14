from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

# Each indexed node occupies key, left child, right child, height.
fn cps_height(nodes: InlineArray[Int64,260], node: Int) -> Int64:
    if node==0: return 0
    return nodes[4*node+3]
fn cps_fix(mut nodes: InlineArray[Int64,260], node: Int):
    let base=4*node
    let lh=cps_height(nodes,Int(nodes[base+1]))
    let rh=cps_height(nodes,Int(nodes[base+2]))
    nodes[base+3]=1+(lh if lh>rh else rh)
fn cps_rotate_right(mut nodes: InlineArray[Int64,260], root: Int) -> Int:
    let base=4*root
    let pivot=Int(nodes[base+1])
    let pb=4*pivot
    nodes[base+1]=nodes[pb+2]
    nodes[pb+2]=Int64(root)
    cps_fix(nodes,root)
    cps_fix(nodes,pivot)
    return pivot
fn cps_rotate_left(mut nodes: InlineArray[Int64,260], root: Int) -> Int:
    let base=4*root
    let pivot=Int(nodes[base+2])
    let pb=4*pivot
    nodes[base+2]=nodes[pb+1]
    nodes[pb+1]=Int64(root)
    cps_fix(nodes,root)
    cps_fix(nodes,pivot)
    return pivot
fn cps_balance(mut nodes: InlineArray[Int64,260], root: Int) -> Int:
    cps_fix(nodes,root)
    let base=4*root
    let difference=cps_height(nodes,Int(nodes[base+1]))-cps_height(nodes,Int(nodes[base+2]))
    if difference>1:
        let child=Int(nodes[base+1])
        let cb=4*child
        if cps_height(nodes,Int(nodes[cb+1]))<cps_height(nodes,Int(nodes[cb+2])):
            nodes[base+1]=Int64(cps_rotate_left(nodes,child))
        return cps_rotate_right(nodes,root)
    if difference< -1:
        let child=Int(nodes[base+2])
        let cb=4*child
        if cps_height(nodes,Int(nodes[cb+2]))<cps_height(nodes,Int(nodes[cb+1])):
            nodes[base+2]=Int64(cps_rotate_right(nodes,child))
        return cps_rotate_left(nodes,root)
    return root
fn cps_insert(mut nodes: InlineArray[Int64,260], root: Int, index: Int) -> Int:
    if root==0: return index
    let base=4*root
    if nodes[4*index]<nodes[base]:
        nodes[base+1]=Int64(cps_insert(nodes,Int(nodes[base+1]),index))
    else:
        nodes[base+2]=Int64(cps_insert(nodes,Int(nodes[base+2]),index))
    return cps_balance(nodes,root)
fn cps_erase(mut nodes: InlineArray[Int64,260], root: Int, key: Int64) -> Int:
    if root==0: return 0
    let base=4*root
    if key<nodes[base]:
        nodes[base+1]=Int64(cps_erase(nodes,Int(nodes[base+1]),key))
    elif key>nodes[base]:
        nodes[base+2]=Int64(cps_erase(nodes,Int(nodes[base+2]),key))
    elif nodes[base+1]==0:
        return Int(nodes[base+2])
    elif nodes[base+2]==0:
        return Int(nodes[base+1])
    else:
        var successor=Int(nodes[base+2])
        while nodes[4*successor+1]!=0: successor=Int(nodes[4*successor+1])
        let replacement=nodes[4*successor]
        nodes[base]=replacement
        nodes[base+2]=Int64(cps_erase(nodes,Int(nodes[base+2]),replacement))
    return cps_balance(nodes,root)
fn cps_range(nodes: InlineArray[Int64,260], root: Int, low: Int64, high: Int64,
             x: Int64, y: Int64, initial: Int64) -> Int64:
    if root==0: return initial
    let base=4*root
    let key=nodes[base]
    var best=initial
    if key>=low: best=cps_range(nodes,Int(nodes[base+1]),low,high,x,y,best)
    if key>=low and key<=high:
        let dx=x-(key%2001-1000)
        let dy=y-(key//2001-1000)
        let distance=dx*dx+dy*dy
        if distance<best: best=distance
    if key<=high: best=cps_range(nodes,Int(nodes[base+2]),low,high,x,y,best)
    return best

@export("closest_pair_sweep")
fn closest_pair_sweep(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64, ImmutAnyOrigin]() or length<5 or length>130: return -1
    if input[0]<2 or input[0]>64: return -1
    let n=Int(input[0])
    if length!=c_size_t(1+2*n): return -1
    var points=InlineArray[Int64,64](fill=0)
    var scratch=InlineArray[Int64,64](fill=0)
    for i in range(n):
        let x=input[1+2*i]
        let y=input[2+2*i]
        if x< -1000 or x>1000 or y< -1000 or y>1000: return -1
        points[i]=(x+1000)*2001+y+1000
    var width=1
    while width<n:
        var begin=0
        while begin<n:
            let middle=min(begin+width,n)
            let end=min(begin+2*width,n)
            var left=begin
            var right=middle
            for destination in range(begin,end):
                if right==end or (left<middle and points[left]<=points[right]):
                    scratch[destination]=points[left]
                    left+=1
                else:
                    scratch[destination]=points[right]
                    right+=1
            begin+=2*width
        for i in range(n): points[i]=scratch[i]
        width*=2
    for i in range(1,n):
        if points[i]==points[i-1]: return 0
    var nodes=InlineArray[Int64,260](fill=0)
    var root=0
    var oldest=0
    var best: Int64=8000001
    for i in range(n):
        let x=points[i]//2001-1000
        let y=points[i]%2001-1000
        while oldest<i:
            let old_x=points[oldest]//2001-1000
            let dx=x-old_x
            if dx*dx<=best: break
            let old_y=points[oldest]%2001-1000
            root=cps_erase(nodes,root,(old_y+1000)*2001+old_x+1000)
            oldest+=1
        var lo: Int64=0
        var hi: Int64=3000
        while lo<hi:
            let middle=(lo+hi+1)//2
            if middle*middle<=best: lo=middle
            else: hi=middle-1
        best=cps_range(nodes,root,(y-lo+1000)*2001,(y+lo+1000)*2001+2000,x,y,best)
        let index=i+1
        nodes[4*index]=(y+1000)*2001+x+1000
        nodes[4*index+3]=1
        root=cps_insert(nodes,root,index)
    return best
