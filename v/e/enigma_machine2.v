module enigma_machine2
fn rotor(which int, x int) int { mut r := 'EGZWVONAHDCLFQMSIPJBYUKXTR'; if which==1 {r='FOBHMDKEXQNRAULPGSJVTYICZW'} else if which==2 {r='ZJXESIUQLHAVRMDOYGTNFWPBKC'}; return int(r[x]-u8(`A`)) }
fn inverse(which int, x int) int { for i in 0..26 {if rotor(which,i)==x{return i}} return 0 }
@[export: 'enigma_machine2']
pub fn enigma_machine2(a &i64, length usize) i64 {
 if unsafe {a==nil} || length<4 || length>16 {return -1}
 n64:=unsafe{a[0]};if n64<0||n64>12||length!=usize(4+n64){return -1}
 mut p:=[3]int{}
 for j in 0..3 {v:=unsafe{a[j+1]};if v<1||v>26{return -1};p[j]=int(v)-1}
 n:=int(n64);for i in 0..n {v:=unsafe{a[4+i]};if v<0||v>25{return -1}}
 mut out:=i64(0)
 for i in 0..n {mut x:=int(unsafe{a[4+i]});for r in 0..3{x=rotor(r,(x+p[r])%26)};x=(x+13)%26;for r in 0..3 {rr:=2-r;x=(inverse(rr,x)-p[rr])%26;if x<0{x+=26}};out=out*26+i64(x);p[0]++;if p[0]==26{p[0]=0;p[1]++;if p[1]==26{p[1]=0;p[2]=(p[2]+1)%26}}}
 return out
}
