package permutation_cipher
import "core:c"
@(export)
permutation_cipher :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
 if v == nil || n < 2 || n > 74 || v[0] < 0 || v[0] > 64 do return -1
 length := int(v[0]); if int(n) < length+2 do return -1
 kp := length+1; if v[kp] < 1 || v[kp] > 8 do return -1
 k := int(v[kp]); if int(n) != kp+k+1 do return -1
 seen: [8]bool
 for i:=0;i<k;i+=1 { x:=v[kp+1+i]; if x<1 || x>i64(k) || seen[int(x-1)] do return -1; seen[int(x-1)]=true }
 text: [128]u8; m:=0
 for i:=0;i<length;i+=1 { x:=v[i+1]; if x<0||x>127 do return -1; c0:=int(x); if c0==32||c0==9||c0==10||c0==11||c0==12||c0==13 do continue; if c0>=97&&c0<=122 do c0-=32; text[m]=u8(c0); m+=1 }
 for m%k!=0 { text[m]='X'; m+=1 }
 h:=u64(0); for b:=0;b<m;b+=k { for j:=0;j<k;j+=1 { h=(h*257+u64(text[b+int(v[kp+1+j]-1)]))%1_000_000_007 } }; return i64(h)
}

