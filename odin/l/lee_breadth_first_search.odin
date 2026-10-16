package lee_breadth_first_search
import "core:c"
@(export)
lee_breadth_first_search :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<6||n>70{return -2};r:=v[0];c:=v[1];sr:=v[2];sc:=v[3];dr:=v[4];dc:=v[5];if r<1||r>8||c<1||c>8||n!=c.size_t(6+r*c)||sr<0||sr>=r||dr<0||dr>=r||sc<0||sc>=c||dc<0||dc>=c{return -2};a:[64]i64;d:[64]i64;q:[64]i64;for i:=i64(0);i<r*c;i+=1{a[i]=v[6+i];if a[i]!=0&&a[i]!=1{return -2};d[i]=-1};s:=sr*c+sc;t:=dr*c+dc;if a[s]==0||a[t]==0{return -1};h:=i64(0);z:=i64(1);q[0]=s;d[s]=0;for h<z{u:=q[h];h+=1;if u==t{return d[u]};y:=u/c;x:=u%c;ys:=[4]i64{y-1,y,y,y+1};xs:=[4]i64{x,x-1,x+1,x};for k:=0;k<4;k+=1{if ys[k]>=0&&ys[k]<r&&xs[k]>=0&&xs[k]<c{w:=ys[k]*c+xs[k];if a[w]==1&&d[w]<0{d[w]=d[u]+1;q[z]=w;z+=1}}}};return -1}
