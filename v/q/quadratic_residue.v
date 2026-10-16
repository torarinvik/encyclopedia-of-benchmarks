module quadratic_residue
@[export: 'quadratic_residue']
pub fn quadratic_residue(input &i64, length usize) i64 {
 if length!=2 || unsafe{input==nil} {return -1}
 unsafe {
 a,p:=input[0],input[1]
 if !(p in [i64(3),5,7,11,13,17,19,23,29,31,37,41,43,47,53]) || a<0 || a>=p {return -1}
 if a==0 {return 0}
 mut r:=i64(1); mut b:=a; mut e:=(p-1)/2
 for e>0 {if e&1!=0 {r=r*b%p}; b=b*b%p; e=e>>1}
 return if r==1 {i64(1)} else {i64(-1)}
 }
}
