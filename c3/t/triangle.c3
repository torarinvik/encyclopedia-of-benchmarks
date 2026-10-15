module triangle;

extern fn double sqrt(double value);
fn void put_f64_le(double value, char* output, usz offset) { ulong bits = @bitcast(ulong, value); for (usz b=0;b<8;b++) { output[offset+b]=(char)(bits&255); bits>>=8; } }
fn long triangle(long* input, usz length, char* output, usz capacity) @export("triangle") {
    if (input == null || length != 6) return -1;
    for (usz i=0;i<6;i++) if (input[i] < -100 || input[i] > 100) return -1;
    double x1=(double)input[0], y1=(double)input[1], x2=(double)input[2], y2=(double)input[3], x3=(double)input[4], y3=(double)input[5];
    if (x1==x2 || x1==x3 || x2==x3 || y3==y1 || y3==y2) return -1;
    double determinant=x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2); if (determinant==0.0) return -1;
    double s1=x1*x1+y1*y1,s2=x2*x2+y2*y2,s3=x3*x3+y3*y3;
    double circum_x=(s1*(y2-y3)+s2*(y3-y1)+s3*(y1-y2))/(2.0*determinant);
    double circum_y=-(s1*(x2-x3)+s2*(x3-x1)+s3*(x1-x2))/(2.0*determinant);
    double side_a=sqrt((x2-x3)*(x2-x3)+(y2-y3)*(y2-y3)),side_b=sqrt((x1-x3)*(x1-x3)+(y1-y3)*(y1-y3)),side_c=sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));
    double perimeter=side_a+side_b+side_c;
    double incenter_x=(side_a*x1+side_b*x2+side_c*x3)/perimeter;
    double incenter_y=(side_a*y1+side_b*y2+side_c*y3)/perimeter;
    double inv_m1=-(x3-x1)/(y3-y1),inv_m2=-(x3-x2)/(y3-y2);
    double rhs1=inv_m2*x1-y1,rhs2=inv_m1*x2-y2,solve_det=inv_m1-inv_m2;
    if (solve_det==0.0) return -1;
    double ortho_x=(-rhs1+rhs2)/solve_det;
    double ortho_y=(inv_m2*rhs2-inv_m1*rhs1)/solve_det;
    if (capacity<48 || output==null) return -2;
    put_f64_le(circum_x,output,0);put_f64_le(circum_y,output,8);put_f64_le(incenter_x,output,16);put_f64_le(incenter_y,output,24);put_f64_le(ortho_x,output,32);put_f64_le(ortho_y,output,40);
    return 48;
}
