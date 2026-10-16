module pascal_triangle_ii;
const long MAX_ROW=30;
const long MODULUS=1000000007;
fn long pascal_triangle_ii(long row) @export("pascal_triangle_ii"){if(row<0||row>MAX_ROW)return -9223372036854775807-1;long[961] triangle;triangle[0]=1;for(usz i=1;i<=(usz)row;i++){triangle[i*31]=1;triangle[i*31+i]=1;for(usz j=1;j<i;j++)triangle[i*31+j]=triangle[(i-1)*31+j-1]+triangle[(i-1)*31+j];}long hash=0;for(usz j=0;j<=(usz)row;j++)hash=(hash*31+triangle[(usz)row*31+j])%MODULUS;return hash;}
