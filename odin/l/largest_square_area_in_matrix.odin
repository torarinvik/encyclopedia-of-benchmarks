package largest_square_area_in_matrix
import "core:c"
@(export)
largest_square_area_in_matrix :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<2||n>66{return -2};r:=v[0];c:=v[1];if r<1||r>8||c<1||c>8||n!=c.size_t(2+r*c){return -2};a:[64]i64;d:[9][9]i64;for i:=i64(0);i<r*c;i+=1{a[i]=v[2+i];if a[i]!=0&&a[i]!=1{return -2}};best:=i64(0);for ii:=r;ii>0;{ii-=1;for jj:=c;jj>0;{jj-=1;if a[ii*c+jj]==1{m:=d[ii+1][jj];if d[ii][jj+1]<m{m=d[ii][jj+1]};if d[ii+1][jj+1]<m{m=d[ii+1][jj+1]};d[ii][jj]=1+m;if d[ii][jj]>best{best=d[ii][jj]}}}};return best}
