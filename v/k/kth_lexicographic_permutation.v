module kth_lexicographic_permutation
@[export: 'kth_lexicographic_permutation']
pub fn kth_lexicographic_permutation(v &i64,n usize)i64{if n!=2{return -1};mut k:=unsafe{v[0]};m:=unsafe{v[1]};if m<2||m>9||k<0{return -1};mut fact:=i64(1);for i in 2..m+1{fact*=i};if k>=fact{return -1};mut a:=[9]i64{};for i in 0..m{a[i]=i};mut code:=m;for block in 1..m{let mut f:=i64(1);for j in 2..block+1{f*=j};idx:=k/f;k%=f;code=code*10+a[idx]+1;for j in idx..block{a[j]=a[j+1]}};return code*10+a[0]+1}
