module versabench_dbms_contract_root
fn put(out &u8,w int,x i64){u:=u64(x);for b in 0..8{unsafe{out[w*8+b]=u8((u>>u64(8*b))&255)}}}
@[export:'versabench_dbms_contract_root']
pub fn versabench_dbms_contract_root(raw &i64,n usize,out &u8,cap usize)i64{
 unsafe {
  if raw==nil||n<3||n>12{return -1};nv:=raw[0];if nv<1||nv>5||int(n)!=1+2*int(nv){return -1};count:=int(nv);mut levels:=[5]i64{};mut entries:=[5]i64{}
  for i in 0..count{levels[i]=raw[1+2*i];entries[i]=raw[2+2*i];if levels[i]<0||levels[i]>4||entries[i]<0||entries[i]>4{return -1};if i+1<count&&(levels[i]==0||entries[i]!=1||levels[i+1]!=levels[i]-1){return -1}}
  if levels[count-1]>0&&entries[count-1]==1{return -1};if levels[count-1]>0&&entries[count-1]==0&&count!=1{return -1};mut root:=0;mut promotions:=0;for levels[root]>0&&entries[root]==1{root++;promotions++};mut fl:=levels[root];mut fc:=entries[root];if fl>0&&fc==0{fl=0;fc=0};if out==nil||cap<24{return -2};put(out,0,i64(promotions));put(out,1,fl);put(out,2,fc);return 24
 }
}
