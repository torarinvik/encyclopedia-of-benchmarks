# Clean-room bounded hierarchical point-location query; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn kp_cross(ax: Int64, ay: Int64, bx: Int64, by: Int64, px: Int64, py: Int64) -> Int64:
    return (bx-ax)*(py-ay)-(by-ay)*(px-ax)

fn kp_inside(qx: Int64, qy: Int64, faces: InlineArray[Int,96], base: Int,
             xy: InlineArray[Int64,32]) -> Bool:
    for e in range(3):
        let a=2*faces[base+e]; let b=2*faces[base+(e+1)%3]
        if kp_cross(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy)<=0: return False
    return True

fn kp_boundary(qx: Int64, qy: Int64, faces: InlineArray[Int,96], base: Int,
               xy: InlineArray[Int64,32]) -> Bool:
    for e in range(3):
        let a=2*faces[base+e]; let b=2*faces[base+(e+1)%3]
        if kp_cross(xy[a],xy[a+1],xy[b],xy[b+1],qx,qy)==0:
            if qx>=min(xy[a],xy[b]) and qx<=max(xy[a],xy[b]) and qy>=min(xy[a+1],xy[b+1]) and qy<=max(xy[a+1],xy[b+1]): return True
    return False

fn kp_overlap(faces: InlineArray[Int,96], a: Int, b: Int, xy: InlineArray[Int64,32]) -> Bool:
    # A separating edge of either CCW triangle proves disjointness.
    for side in range(2):
        let first=a if side==0 else b
        let second=b if side==0 else a
        for e in range(3):
            let u=2*faces[first+e]; let v=2*faces[first+(e+1)%3]
            var all_outside=True
            for j in range(3):
                let p=2*faces[second+j]
                if kp_cross(xy[u],xy[u+1],xy[v],xy[v+1],xy[p],xy[p+1])>=0: all_outside=False
            if all_outside: return False
    return True

@export("kirkpatrick_hierarchical_point_location")
fn kirkpatrick_hierarchical_point_location(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                                          output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<14 or length>268: return -1
    let nv64=input[0]; let nl64=input[1]; let qx=input[2]; let qy=input[3]
    if nv64<3 or nv64>16 or nl64<1 or nl64>4 or qx < -1000 or qx>1000 or qy < -1000 or qy>1000: return -1
    let nv=Int(nv64); let levels=Int(nl64)
    if length<c_size_t(4+2*nv): return -1
    var xy=InlineArray[Int64,32](fill=0)
    var faces=InlineArray[Int,96](fill=0)
    var face_counts=InlineArray[Int,4](fill=0)
    var child_counts=InlineArray[Int,32](fill=0)
    var children=InlineArray[Int,256](fill=0)
    var pos=4
    for v in range(nv):
        xy[2*v]=input[pos]; xy[2*v+1]=input[pos+1]; pos+=2
        if xy[2*v] < -1000 or xy[2*v]>1000 or xy[2*v+1] < -1000 or xy[2*v+1]>1000: return -1
    for level in range(levels):
        if pos>=Int(length): return -1
        let count64=input[pos]; pos+=1
        if count64<1 or count64>8 or (level==0 and count64!=1): return -1
        let count=Int(count64); face_counts[level]=count
        for f in range(count):
            if pos+3>Int(length): return -1
            let base=(level*8+f)*3
            for k in range(3):
                let vertex=input[pos]; pos+=1
                if vertex<0 or vertex>=nv64: return -1
                faces[base+k]=Int(vertex)
            let a=2*faces[base]; let b=2*faces[base+1]; let c=2*faces[base+2]
            if faces[base]==faces[base+1] or faces[base]==faces[base+2] or faces[base+1]==faces[base+2]: return -1
            if kp_cross(xy[a],xy[a+1],xy[b],xy[b+1],xy[c],xy[c+1])<=0: return -1
        if level+1<levels:
            for f in range(count):
                if pos>=Int(length): return -1
                let count64=input[pos]; pos+=1
                if count64<1 or count64>8 or pos+Int(count64)>Int(length): return -1
                let count=Int(count64); child_counts[level*8+f]=count
                let base=(level*8+f)*8
                for j in range(count):
                    let child=input[pos]; pos+=1
                    if child<0 or child>=8: return -1
                    if j>0 and child<=Int64(children[base+j-1]): return -1
                    children[base+j]=Int(child)
    if pos!=Int(length): return -1
    for level in range(levels-1):
        for f in range(face_counts[level]):
            for j in range(child_counts[level*8+f]):
                let child=children[(level*8+f)*8+j]
                if child>=face_counts[level+1]: return -1
                if not kp_overlap(faces,(level*8+f)*3,((level+1)*8+child)*3,xy): return -1
    for level in range(levels):
        var hits=0
        for f in range(face_counts[level]):
            let base=(level*8+f)*3
            if kp_boundary(qx,qy,faces,base,xy): return -1
            if kp_inside(qx,qy,faces,base,xy): hits+=1
        if hits!=1: return -1
    var face=0; var tests=1
    for level in range(levels-1):
        var found = -1
        for j in range(child_counts[level*8+face]):
            let child=children[(level*8+face)*8+j]
            tests+=1
            if kp_inside(qx,qy,faces,((level+1)*8+child)*3,xy): found=child; break
        if found<0: return -1
        face=found
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<16: return -2
    for i in range(2):
        let bits=UInt64(face if i==0 else tests)
        for byte in range(8): output[8*i+byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return 16
