package quadratic_residue
import "core:c"
@(export)
quadratic_residue :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
 if input==nil || length!=2 do return -1
 a,p:=input[0],input[1]
 if !(p==3||p==5||p==7||p==11||p==13||p==17||p==19||p==23||p==29||p==31||p==37||p==41||p==43||p==47||p==53)||a<0||a>=p do return -1
 if a==0 do return 0
 r,b,e:=i64(1),a,(p-1)/2
 for e>0 { if e&1!=0 do r=r*b%p; b=b*b%p; e=e>>1 }
 if r==1 do return 1
 return -1
}
