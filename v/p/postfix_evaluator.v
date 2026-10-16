module postfix_evaluator
@[export: 'postfix_evaluator']
pub fn postfix_evaluator(v &i64, n usize) i64 {
 unsafe {
  if v==nil || n<2 || n>129 || v[0]<1 || v[0]>128 || n!=usize(v[0]+1) { return -1 }
  mut st:=[]i32{len:0,cap:128};
  for i in 1..n { t:=v[i]
   if t == -9000000000000000001 || t == -9000000000000000002 || t == -9000000000000000003 || t == -9000000000000000004 {
    if st.len<2 {return -1}; b:=st.pop();a:=st.pop();mut z:=i32(0)
    if t == -9000000000000000001 {z=i32(u32(a)+u32(b))} else if t == -9000000000000000002 {z=i32(u32(a)-u32(b))} else if t == -9000000000000000003 {z=i32(u32(a)*u32(b))} else {if b==0{return -1};z=if a==i32(-2147483648)&&b == -1 {i32(-2147483648)} else {a/b}}
    st << z
   } else {if t < -2147483648 || t > 2147483647 || st.len>=128{return -1};st << i32(t)}
  }
  if st.len==1{return i64(st[0])};return -1
 }
}
