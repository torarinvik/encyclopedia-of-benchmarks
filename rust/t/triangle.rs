fn put_f64_le(out:&mut [u8],offset:usize,value:f64){out[offset..offset+8].copy_from_slice(&value.to_le_bytes());}

#[no_mangle]
pub unsafe extern "C" fn triangle(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length!=6{return -1;}
    let v=std::slice::from_raw_parts(input,length);
    if v.iter().any(|&x|!(-100..=100).contains(&x)){return -1;}
    let (x1,y1,x2,y2,x3,y3)=(v[0] as f64,v[1] as f64,v[2] as f64,v[3] as f64,v[4] as f64,v[5] as f64);
    if x1==x2||x1==x3||x2==x3||y3==y1||y3==y2{return -1;}
    let determinant=x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2);if determinant==0.0{return -1;}
    let (s1,s2,s3)=(x1*x1+y1*y1,x2*x2+y2*y2,x3*x3+y3*y3);
    let circum_x=(s1*(y2-y3)+s2*(y3-y1)+s3*(y1-y2))/(2.0*determinant);
    let circum_y=-(s1*(x2-x3)+s2*(x3-x1)+s3*(x1-x2))/(2.0*determinant);
    let side_a=(x2-x3).hypot(y2-y3);let side_b=(x1-x3).hypot(y1-y3);let side_c=(x1-x2).hypot(y1-y2);let perimeter=side_a+side_b+side_c;
    let incenter_x=(side_a*x1+side_b*x2+side_c*x3)/perimeter;let incenter_y=(side_a*y1+side_b*y2+side_c*y3)/perimeter;
    let inv_m1=-(x3-x1)/(y3-y1);let inv_m2=-(x3-x2)/(y3-y2);let rhs1=inv_m2*x1-y1;let rhs2=inv_m1*x2-y2;let solve_det=inv_m1-inv_m2;
    if solve_det==0.0{return -1;}
    let ortho_x=(-rhs1+rhs2)/solve_det;let ortho_y=(inv_m2*rhs2-inv_m1*rhs1)/solve_det;
    if capacity<48||output.is_null(){return -2;}
    let values=[circum_x,circum_y,incenter_x,incenter_y,ortho_x,ortho_y];let bytes=std::slice::from_raw_parts_mut(output,48);
    for (i,value) in values.into_iter().enumerate(){put_f64_le(bytes,i*8,value);}
    48
}
