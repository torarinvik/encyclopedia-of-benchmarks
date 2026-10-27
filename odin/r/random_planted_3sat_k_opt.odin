package random_planted_3sat_k_opt
import "core:c"

MAX_VARS :: 12
MAX_CLAUSES :: 32
MAX_INPUT :: 98
MAX_OUTPUT :: 104
put_i64 :: proc(out: [^]u8, at: int, value: i64) { bits:=u64(value); for i:=0;i<8;i+=1 { out[at+i]=u8(bits&255);bits>>=8 } }
sat_set :: proc(clauses: [^]int,m,n:int,code:u32)->u32 {
    set:u32=0
    for clause:=0;clause<m;clause+=1 {
        satisfied:=false
        for j:=0;j<3;j+=1 { lit:=clauses[3*clause+j];v:=int(abs(lit))-1;truth:=((code>>u32(n-1-v))&1)!=0;if truth==(lit>0) { satisfied=true } }
        if satisfied { set|=u32(1)<<u32(clause) }
    }
    return set
}

@(export)
random_planted_3sat_k_opt :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil || length<2 || length>MAX_INPUT || input[0]<3 || input[0]>MAX_VARS || input[1]<0 || input[1]>MAX_CLAUSES { return -1 }
    n,m:=int(input[0]),int(input[1]);if length!=c.size_t(2+3*m) { return -1 }
    clauses:[MAX_CLAUSES*3]int;positive:[MAX_VARS]int;negative:[MAX_VARS]int
    for clause:=0;clause<m;clause+=1 {
        seen:[MAX_VARS]bool
        for j:=0;j<3;j+=1 {
            raw:=input[2+3*clause+j];if raw==0 || raw < -i64(n) || raw>i64(n) { return -1 }
            lit:=int(raw);v:=int(abs(lit))-1;if seen[v] { return -1 };seen[v]=true;clauses[3*clause+j]=lit
            if lit>0 { positive[v]+=1 } else { negative[v]+=1 }
        }
    }
    current:u32=0
    for v:=0;v<n;v+=1 { if positive[v]>negative[v] { current|=u32(1)<<u32(n-1-v) } }
    full:u32=0;if m==32 { full=0xFFFF_FFFF } else if m>0 { full=(u32(1)<<u32(m))-1 }
    k:=1;status:i64=0
    for {
        before:=sat_set(&clauses[0],m,n,current);if before==full { status=1;break }
        found:=false
        limit:=u32(1)<<u32(n)
        for candidate:u32=0;candidate<limit;candidate+=1 {
            diff:=current^candidate;distance:=0
            for diff!=0 { diff&=diff-1;distance+=1 }
            if distance==0 || distance>k { continue }
            after:=sat_set(&clauses[0],m,n,candidate)
            if after!=before && (after&before)==before { current=candidate;found=true;break }
        }
        if found { continue };if k==n { status=0;break };k+=1
    }
    bytes:=8*(n+1);if output==nil || capacity<c.size_t(bytes) { return -2 }
    staged:[MAX_OUTPUT]u8;put_i64(&staged[0],0,status)
    for v:=0;v<n;v+=1 { value:i64=-1;if ((current>>u32(n-1-v))&1)!=0 { value=1 };put_i64(&staged[0],8*(v+1),value) }
    for i:=0;i<bytes;i+=1 { output[i]=staged[i] }
    return i64(bytes)
}
