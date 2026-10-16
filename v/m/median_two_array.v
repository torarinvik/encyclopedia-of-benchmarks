module median_two_array
@[export: 'median_two_array']
pub fn median_two_array(a &i64,length usize) f64 {
 bad:= -1.0e300
 if unsafe{a==nil}||length<2||length>259{return bad}
 n1v:=unsafe{a[0]};n2v:=unsafe{a[1]};if n1v<0||n2v<0||n1v+n2v<1||n1v+n2v>256||length!=usize(n1v+n2v+2){return bad}
 n:=int(n1v+n2v);n1:=int(n1v);mut vals:=[256]i64{}
 for i in 0..n{vals[i]=unsafe{a[i+2]};if vals[i]<-1000000||vals[i]>1000000{return bad};if i<n1&&i>0&&vals[i]<vals[i-1]{return bad};if i>=n1&&i>n1&&vals[i]<vals[i-1]{return bad}}
 for i in 1..n{x:=vals[i];mut j:=i;for j>0&&vals[j-1]>x{vals[j]=vals[j-1];j--};vals[j]=x}
 m:=n/2;if n%2==1{return f64(vals[m])};return (f64(vals[m-1])+f64(vals[m]))/2.0
}
