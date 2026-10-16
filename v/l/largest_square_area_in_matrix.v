module largest_square_area_in_matrix
@[export: 'largest_square_area_in_matrix']
pub fn largest_square_area_in_matrix(v &i64,n usize)i64{if n<2||n>66{return -2};r:=unsafe{v[0]};c:=unsafe{v[1]};if r<1||r>8||c<1||c>8||n!=usize(2+r*c){return -2};mut a:=[64]i64{};mut d:=[9][9]i64{};for i in 0..r*c{a[i]=unsafe{v[2+i]};if a[i]!=0&&a[i]!=1{return -2}};mut best:=i64(0);for ii in 0..r{for jj in 0..c{i:=r-1-ii;j:=c-1-jj;if a[i*c+j]==1{d[i][j]=1+min(d[i+1][j],min(d[i][j+1],d[i+1][j+1]));if d[i][j]>best{best=d[i][j]}}}};return best}
