package random_planted_3sat_majority_vote
import "core:c"

MAX_VARS :: 12
MAX_CLAUSES :: 32
MAX_INPUT :: 98
MAX_OUTPUT :: 96
put_i64 :: proc(out: [^]u8, at: int, value: i64) { bits:=u64(value); for i:=0;i<8;i+=1 { out[at+i]=u8(bits&255);bits>>=8 } }

@(export)
random_planted_3sat_majority_vote :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil || length<2 || length>MAX_INPUT || input[0]<3 || input[0]>MAX_VARS || input[1]<0 || input[1]>MAX_CLAUSES { return -1 }
    n,m:=int(input[0]),int(input[1]);if length!=c.size_t(2+3*m) { return -1 }
    positive:[MAX_VARS]int;negative:[MAX_VARS]int
    for clause:=0;clause<m;clause+=1 {
        seen:[MAX_VARS]bool
        for j:=0;j<3;j+=1 {
            raw:=input[2+3*clause+j];if raw==0 || raw < -i64(n) || raw>i64(n) { return -1 }
            lit:=int(raw);v:=int(abs(lit))-1;if seen[v] { return -1 };seen[v]=true
            if lit>0 { positive[v]+=1 } else { negative[v]+=1 }
        }
    }
    bytes:=8*n;if output==nil || capacity<c.size_t(bytes) { return -2 }
    staged:[MAX_OUTPUT]u8
    for v:=0;v<n;v+=1 { value:i64=-1;if positive[v]>negative[v] { value=1 };put_i64(&staged[0],8*v,value) }
    for i:=0;i<bytes;i+=1 { output[i]=staged[i] }
    return i64(bytes)
}
