module paranthesis_matching
@[export: 'paranthesis_matching']
pub fn paranthesis_matching(v &i64,n usize)i64{
 unsafe{if v==nil||n<2||n>100||v[0]<1||v[0]>99||n!=usize(v[0]+1){return -1};mut st:=[]i64{len:0,cap:99};for i in 1..n{x:=v[i];if x<33||x>126{return -1};if x==40||x==123||x==91||x==60{st<<x}else if x==41||x==125||x==93||x==62{want:=i64(60);if x==41{want=40}else if x==125{want=123}else if x==93{want=91};if st.len==0{return 0};if st.pop()!=want{return 0}}else{return 0}};if st.len==0{return 1};return 0}
}
