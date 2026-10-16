module flatten_nested_list
@[export: 'flatten_nested_list']
pub fn flatten_nested_list(v &i64,n usize)i64{
 if isnil(v)||n==0||n>255||v[0]!=i64(-9223372036854775808){return -1}
 open:=i64(-9223372036854775808);close:=open+1;mut depth:=0;mut closed:=false;mut h:=u64(0xcbf29ce484222325)
 for i in 0..n{x:=v[i];if x==open{if closed||(depth==0&&i!=0){return -1};depth++;if depth>16{return -1}}else if x==close{if depth==0{return -1};depth--;if depth==0{closed=true;if i+1!=n{return -1}}}else{if depth==0||x< -1000000||x>1000000{return -1};u:=u64(x);for b in 0..8{h=(h^((u>>(8*b))&255))*u64(0x100000001b3)}}}
 if depth!=0||!closed{return -1}
 return i64(h)
}
