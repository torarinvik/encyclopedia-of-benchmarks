from std.math import fabs, sqrt
fn p144_close(left:Float64,right:Float64)->Bool:
    let la=fabs(left);let ra=fabs(right);let scale=la if la>ra else ra
    return fabs(left-right)<=1.0e-9*scale
fn p144_next(x:Float64,y:Float64,incoming:Float64)->Tuple[Float64,Float64,Float64]:
    let normal=y/4.0/x;let s2=2.0*normal/(1.0+normal*normal);let c2=(1.0-normal*normal)/(1.0+normal*normal)
    let outgoing=(s2-c2*incoming)/(c2+s2*incoming)
    let quad=outgoing*outgoing+4.0;let line=2.0*outgoing*(y-outgoing*x)
    let diff=y-outgoing*x;let constant=diff*diff-100.0
    let disc=line*line-4.0*quad*constant
    let xm=(-line-sqrt(disc))/(2.0*quad);let xp=(-line+sqrt(disc))/(2.0*quad)
    let nx=xm if p144_close(xp,x) else xp
    let ny=y+outgoing*(nx-x)
    return (nx,ny,outgoing)
@export("problem144")
fn problem144(first_x:Float64,first_y:Float64) abi("C")->Float64:
    let invalid=Float64(-1.0e300)
    if first_x!=first_x or first_y!=first_y or first_x<1.0e-5 or first_x>5.0 or first_y< -10.0 or first_y>0.0:return invalid
    let residual=4.0*first_x*first_x+first_y*first_y-100.0
    if fabs(residual)>1.0e-6:return invalid
    var x=first_x;var y=first_y;var gradient=(10.1-y)/(0.0-x);var reflections=0
    while !(x>=-0.01 and x<=0.01 and y>0.0):
        if reflections>=10000:return invalid
        let next=p144_next(x,y,gradient);x=next.0;y=next.1;gradient=next.2
        if x!=x or y!=y:return invalid
        reflections+=1
    return Float64(reflections)
