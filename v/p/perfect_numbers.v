@[export: 'perfect_numbers']
pub fn perfect_numbers(v &i64, n usize) i64 {
 unsafe {
  if v==nil || n!=1 || v[0]<0 || v[0]>1_000_000_000 { return -1 }
  x:=v[0]; if x<=1 { return 0 }; mut total:=i64(1); mut d:=i64(2)
  for d<=x/d { if x%d==0 { total+=d; q:=x/d; if d!=q { total+=q } }; d++ }
  return i64(total==x)
 }
}

