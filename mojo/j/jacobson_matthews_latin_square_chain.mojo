from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_N = 4
comptime MAX_CELLS = 64
comptime MAX_MOVES = 48
comptime MAX_WORDS = 66

@fieldwise_init
struct JM_Move(Copyable):
    var i: Int
    var j: Int
    var k: Int
    var ip: Int
    var jp: Int
    var kp: Int

fn jm_at(n: Int, i: Int, j: Int, k: Int) -> Int:
    return (i*n+j)*n+k

fn jm_select_move(tensor: InlineArray[Int64, MAX_CELLS], n: Int, choice: Int) -> JM_Move:
    var moves = InlineArray[JM_Move, MAX_MOVES](fill=JM_Move(i=-1,j=0,k=0,ip=0,jp=0,kp=0))
    var defects = 0
    var pi = 0
    var pj = 0
    var pk = 0
    var count = 0
    for i in range(n):
        for j in range(n):
            for k in range(n):
                if tensor[jm_at(n,i,j,k)] == -1:
                    defects += 1
                    pi = i
                    pj = j
                    pk = k
    if defects > 1: return JM_Move(i=-1,j=0,k=0,ip=0,jp=0,kp=0)
    if defects == 1:
        for ip in range(n):
            for jp in range(n):
                for kp in range(n):
                    if (ip != pi and jp != pj and kp != pk and
                            tensor[jm_at(n,pi,pj,kp)] == 1 and
                            tensor[jm_at(n,pi,jp,pk)] == 1 and tensor[jm_at(n,ip,pj,pk)] == 1):
                        moves[count] = JM_Move(i=pi,j=pj,k=pk,ip=ip,jp=jp,kp=kp)
                        count += 1
        if count != 8: return JM_Move(i=-1,j=0,k=0,ip=0,jp=0,kp=0)
    else:
        for i in range(n):
            for j in range(n):
                for k in range(n):
                    if tensor[jm_at(n,i,j,k)] != 0: continue
                    var ip = n
                    var jp = n
                    var kp = n
                    for x in range(n):
                        if tensor[jm_at(n,x,j,k)] == 1: ip=x
                    for x in range(n):
                        if tensor[jm_at(n,i,x,k)] == 1: jp=x
                    for x in range(n):
                        if tensor[jm_at(n,i,j,x)] == 1: kp=x
                    if ip == n or jp == n or kp == n: return JM_Move(i=-1,j=0,k=0,ip=0,jp=0,kp=0)
                    moves[count] = JM_Move(i=i,j=j,k=k,ip=ip,jp=jp,kp=kp)
                    count += 1
        if count != n*n*n-n*n: return JM_Move(i=-1,j=0,k=0,ip=0,jp=0,kp=0)
    if choice < 0 or choice >= count: return JM_Move(i=-1,j=0,k=0,ip=0,jp=0,kp=0)
    return moves[choice]

fn jm_apply_choice(mut tensor: InlineArray[Int64, MAX_CELLS], n: Int, choice: Int) -> Bool:
    let m = jm_select_move(tensor,n,choice)
    if m.i < 0: return False
    tensor[jm_at(n,m.i,m.j,m.k)] += 1
    tensor[jm_at(n,m.ip,m.jp,m.k)] += 1
    tensor[jm_at(n,m.ip,m.j,m.kp)] += 1
    tensor[jm_at(n,m.i,m.jp,m.kp)] += 1
    tensor[jm_at(n,m.ip,m.j,m.k)] -= 1
    tensor[jm_at(n,m.i,m.jp,m.k)] -= 1
    tensor[jm_at(n,m.i,m.j,m.kp)] -= 1
    tensor[jm_at(n,m.ip,m.jp,m.kp)] -= 1
    return True

fn jm_write_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset+byte] = UInt8((bits>>(byte*8))&UInt64(255))

@export("jacobson_matthews_latin_square_chain")
fn jacobson_matthews_latin_square_chain(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 14: return -1
    if (input[0] < 2 or input[0] > MAX_N or input[1] < 0 or input[1] > 12 or
            Int(length) != 2 + Int(input[1])): return -1
    let n = Int(input[0])
    let steps = Int(input[1])
    var tensor = InlineArray[Int64, MAX_CELLS](fill=0)
    for i in range(n):
        for j in range(n): tensor[jm_at(n,i,j,(i+j)%n)] = 1
    for step in range(steps):
        let choice = input[2+step]
        if choice < 0 or choice >= MAX_MOVES or not jm_apply_choice(mut tensor,n,Int(choice)): return -1
    let word_count=2+n*n*n
    let output_bytes=word_count*8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    var words=InlineArray[Int64,MAX_WORDS](fill=0)
    words[0]=input[0]; words[1]=input[1]
    for i in range(n*n*n): words[2+i]=tensor[i]
    for i in range(word_count): jm_write_i64_le(output,i*8,words[i])
    Int64(output_bytes)
