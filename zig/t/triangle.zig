fn putF64Le(out:[*]u8,offset:usize,value:f64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[offset+b]=@truncate(bits>>@intCast(8*b));}
pub export fn triangle(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length!=6)return -1;for(0..6)|i|{if(input[i]<-100 or input[i]>100)return -1;}
    const x1=@as(f64,@floatFromInt(input[0]));const y1=@as(f64,@floatFromInt(input[1]));const x2=@as(f64,@floatFromInt(input[2]));const y2=@as(f64,@floatFromInt(input[3]));const x3=@as(f64,@floatFromInt(input[4]));const y3=@as(f64,@floatFromInt(input[5]));
    if(x1==x2 or x1==x3 or x2==x3 or y3==y1 or y3==y2)return -1;
    const determinant=x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2);if(determinant==0.0)return -1;
    const s1=x1*x1+y1*y1;const s2=x2*x2+y2*y2;const s3=x3*x3+y3*y3;
    const circum_x=(s1*(y2-y3)+s2*(y3-y1)+s3*(y1-y2))/(2.0*determinant);
    const circum_y=-(s1*(x2-x3)+s2*(x3-x1)+s3*(x1-x2))/(2.0*determinant);
    const side_a=@sqrt((x2-x3)*(x2-x3)+(y2-y3)*(y2-y3));const side_b=@sqrt((x1-x3)*(x1-x3)+(y1-y3)*(y1-y3));const side_c=@sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));const perimeter=side_a+side_b+side_c;
    const incenter_x=(side_a*x1+side_b*x2+side_c*x3)/perimeter;const incenter_y=(side_a*y1+side_b*y2+side_c*y3)/perimeter;
    const inv_m1=-(x3-x1)/(y3-y1);const inv_m2=-(x3-x2)/(y3-y2);const rhs1=inv_m2*x1-y1;const rhs2=inv_m1*x2-y2;const solve_det=inv_m1-inv_m2;
    if(solve_det==0.0)return -1;const ortho_x=(-rhs1+rhs2)/solve_det;const ortho_y=(inv_m2*rhs2-inv_m1*rhs1)/solve_det;
    if(capacity<48 or output==null)return -2;const vals=[_]f64{circum_x,circum_y,incenter_x,incenter_y,ortho_x,ortho_y};for(vals,0..)|value,i|putF64Le(output,i*8,value);return 48;
}
