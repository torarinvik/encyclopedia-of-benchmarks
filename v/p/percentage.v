module percentage
@[export: 'percentage']
pub fn percentage(v &i64,n usize)i64{
 unsafe{if v==nil||n!=3||v[0]<1||v[0]>100000||v[1]<1||v[1]>100000||v[2]<1||v[2]>4{return -1};mut scale:=i64(1);for _ in 0..int(v[2]){scale*=10};product:=v[0]*v[1]*scale;if product<100{return -1};return product/100}
}
