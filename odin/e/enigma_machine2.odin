package enigma_machine2
import "core:c"
import "core:runtime"
R1 :: "EGZWVONAHDCLFQMSIPJBYUKXTR"
R2 :: "FOBHMDKEXQNRAULPGSJVTYICZW"
R3 :: "ZJXESIUQLHAVRMDOYGTNFWPBKC"
rotor :: proc(which, x: int) -> int { s:=R1; if which==1{s=R2} else if which==2{s=R3}; return int(s[x]-'A') }
inverse :: proc(which, x: int) -> int { for i:=0;i<26;i+=1 {if rotor(which,i)==x{return i}} return 0 }
@(export)
enigma_machine2 :: proc "c" (a: [^]i64, length: c.size_t) -> i64 {
 context = runtime.default_context()
 if a==nil || length<4 || length>16 do return -1
 n64:=a[0];if n64<0||n64>12||int(length)!=4+int(n64) do return -1
 p: [3]int
 for j:=0;j<3;j+=1 {if a[j+1]<1||a[j+1]>26 do return -1;p[j]=int(a[j+1])-1}
 n:=int(n64);for i:=0;i<n;i+=1 {if a[4+i]<0||a[4+i]>25 do return -1}
 out:=i64(0)
 for i:=0;i<n;i+=1 {x:=int(a[4+i]);for r:=0;r<3;r+=1{x=rotor(r,(x+p[r])%26)};x=(x+13)%26;for r:=2;r>=0;r-=1{x=(inverse(r,x)-p[r])%26;if x<0{x+=26}};out=out*26+i64(x);p[0]+=1;if p[0]==26{p[0]=0;p[1]+=1;if p[1]==26{p[1]=0;p[2]=(p[2]+1)%26}}}
 return out
}
