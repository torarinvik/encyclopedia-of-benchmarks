module monotonic_array
@[export: 'monotonic_array']
pub fn monotonic_array(v &i64,n usize)i64{
 if n>256||(isnil(v)&&n>0){return -1}
 mut inc:=true;mut dec:=true
 for i in 0..n{if v[i]< -1000000000||v[i]>1000000000{return -1}}
 for i in 1..n{if v[i-1]>v[i]{inc=false};if v[i-1]<v[i]{dec=false}}
 if inc||dec{return 1};return 0
}
