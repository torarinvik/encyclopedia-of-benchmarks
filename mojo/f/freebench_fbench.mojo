# Independent bounded John Walker Floating Point Benchmark, derived from the
# Marinchip Interactive Lens Design System (December 1980). Pinned source:
# lac-dcc/Benchmarks, Misc/fbench/fbench.c, commit 5d7b75df749241efa7a6e6f5be613d3fcc5cce38.
# Original terms permit use, distribution, and modification with origin preserved.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sin, cos, tan, asin, isfinite
from std.memory import ImmutAnyOrigin, UnsafePointer

fn fbench_trace(line: Int, initial_height: Float64, paraxial: Bool) -> (Float64,Float64):
    let wavelengths=InlineArray[Float64,9](0.0,7621.0,6869.955,6562.816,5895.944,5269.557,4861.344,4340.477,3968.494)
    let radii=InlineArray[Float64,4](27.05,-16.68,-16.68,-78.1)
    let indices=InlineArray[Float64,4](1.5137,1.0,1.6164,1.0)
    let abbe=InlineArray[Float64,4](63.6,0.0,36.7,0.0)
    let thickness=InlineArray[Float64,4](0.52,0.138,0.38,0.0)
    var distance=Float64(0); var slope=Float64(0); var from_index=Float64(1)
    var height=initial_height
    for surface in range(4):
        let radius=radii[surface]
        let nominal=indices[surface]
        var to_index=nominal
        if to_index>1.0:
            to_index+=((wavelengths[4]-wavelengths[line])/(wavelengths[3]-wavelengths[6]))*((nominal-1.0)/abbe[surface])
        if paraxial:
            if radius!=0.0:
                var incidence=Float64(0)
                if distance==0.0:
                    slope=0.0; incidence=height/radius
                else: incidence=((distance-radius)/radius)*slope
                let refraction=(from_index/to_index)*incidence
                let old=slope
                slope=slope+incidence-refraction
                if distance!=0.0: height=distance*old
                distance=height/slope
            else:
                distance=distance*(to_index/from_index)
                slope=slope*(from_index/to_index)
        elif radius!=0.0:
            var incidence=Float64(0)
            if distance==0.0:
                slope=0.0; incidence=height/radius
            else: incidence=((distance-radius)/radius)*sin(slope)
            let incidence_angle=asin(incidence)
            let refraction=(from_index/to_index)*incidence
            let old=slope
            slope=slope+incidence_angle-asin(refraction)
            var sagitta=sin((old+incidence_angle)/2.0)
            sagitta=2.0*radius*sagitta*sagitta
            distance=(radius*sin(old+incidence_angle))*(1.0/tan(slope))+sagitta
        else:
            let angle = -asin((from_index/to_index)*sin(slope))
            distance=distance*((to_index*cos(-angle))/(from_index*cos(slope)))
            slope = -angle
        from_index=to_index
        if surface<3: distance-=thickness[surface]
    return (distance,slope)

@export("freebench_fbench")
fn freebench_fbench(values: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1: return -1.0e300
    if values[0]<1 or values[0]>16: return -1.0e300
    var total=Float64(0)
    for step in range(Int(values[0])):
        let height=2.0+0.0002*Float64(step)
        let marginal=fbench_trace(4,height,False)
        let paraxial=fbench_trace(4,height,True)
        let c=fbench_trace(3,height,False)
        let f=fbench_trace(6,height,False)
        let spherical=paraxial[0]-marginal[0]
        let sine_condition=1.0-(paraxial[0]*paraxial[1])/(sin(marginal[1])*marginal[0])
        let chromatic=f[0]-c[0]
        total+=spherical+sine_condition+chromatic
    return total if isfinite(total) else -1.0e300
