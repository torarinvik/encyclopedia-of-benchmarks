module payback
@[export: 'payback']
pub fn payback(v &i64,n usize)i64{
 unsafe{if v==nil||n<1||n>129||v[0]<0||v[0]>128||n!=usize(v[0]+1){return -2};mut total:=i64(0);for i in 1..n{if v[i]<-1000000||v[i]>1000000{return -2};total+=v[i];if total>=0{return i64(i-1)}};return -1}
}
