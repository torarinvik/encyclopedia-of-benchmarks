/*
 * Independent bounded FreeBench/distray profile.
 * Scene and ray-tracing behavior are attributed to Marcus Geelnard;
 * benchmarkification is attributed to Peter Rundberg (biff@ce.chalmers.se).
 * No license grant is inferred from the pinned upstream source.
 */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kWidth = 640;
constexpr int kHeight = 480;
constexpr double kEpsilon = 1.0e-5;
constexpr double kMaxT = 1.0e5;
constexpr int kMaxRecursion = 6;
constexpr int kDistributionLevels = 3;

struct Vec3 { double x, y, z; };
struct Texture { Vec3 color; double diffuse, reflect, roughness; };
struct Sphere { Vec3 center; double radius; Texture texture; };
struct Hit { double distance; Vec3 point, normal; Texture texture; bool found; };
struct Context { int distribution; std::uint32_t state; };

constexpr Sphere kSpheres[4] = {
    {{0.0,4.0,1.0},1.0,{{1.0,0.4,0.0},0.4,0.8,0.02}},
    {{-1.0,3.0,0.4},0.4,{{0.5,0.3,1.0},0.5,0.9,0.01}},
    {{-0.3,1.0,0.4},0.4,{{0.1,0.95,0.2},0.6,0.8,0.01}},
    {{1.0,2.0,0.4},0.4,{{0.86,0.83,0.0},0.7,0.6,0.01}}
};
constexpr Texture kGround[2] = {
    {{0.0,0.1,0.5},0.8,0.44,0.02},
    {{0.6,1.0,0.5},0.8,0.44,0.01}
};
constexpr Vec3 kLight{-3.0,1.0,5.0};
constexpr Vec3 kCamera{1.5,-1.4,1.2};
constexpr Vec3 kCameraRight{3.0,1.0,0.0};
constexpr Vec3 kCameraDirection{-1.0,3.0,0.0};
constexpr Vec3 kCameraUp{0.0,0.0,2.3717};
constexpr Vec3 kSkyHorizon{0.5,0.3,0.7};
constexpr Vec3 kSkyZenith{0.0,0.0,0.2};

Vec3 add(Vec3 a, Vec3 b) { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
Vec3 subtract(Vec3 a, Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
Vec3 multiply(Vec3 a, double factor) { return {a.x*factor,a.y*factor,a.z*factor}; }
double dot(Vec3 a, Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
double length(Vec3 a) { return std::sqrt(dot(a,a)); }

double jitter(Context& context) {
    context.state = static_cast<std::uint32_t>(
        (UINT64_C(1103515245)*context.state+UINT64_C(12345))&UINT64_C(0x7fffffff));
    return 1.0-static_cast<double>(context.state)/static_cast<double>(UINT32_C(0x3fffffff));
}

Vec3 distributedVector(Context& context, Vec3 normal, double sa, double sb) {
    Vec3 a{}, b{};
    if (std::fabs(normal.z)>kEpsilon) {
        a={normal.y*normal.z,-normal.x*normal.z,0.0};
        b={a.y*normal.z,-a.x*normal.z,a.x*normal.y-a.y*normal.x};
    } else {
        a={normal.y,-normal.x,0.0};
        b={0.0,0.0,1.0};
    }
    const double normalLength=length(normal);
    a=multiply(a,sa*(normalLength/length(a))*jitter(context));
    b=multiply(b,sb*(normalLength/length(b))*jitter(context));
    return add(a,b);
}

Vec3 reflect(Vec3 incident, Vec3 normal) {
    return add(incident,multiply(normal,-2.0*dot(incident,normal)/dot(normal,normal)));
}

Hit intersect(Vec3 origin, Vec3 direction) {
    Hit hit{-1.0,{0.0,0.0,0.0},{0.0,0.0,0.0},{},false};
    if (std::fabs(direction.z)>kEpsilon) {
        const double candidate=-origin.z/direction.z;
        if (candidate>kEpsilon && candidate<kMaxT) {
            hit.distance=candidate;
            hit.point=add(origin,multiply(direction,candidate));
            hit.normal={0.0,0.0,1.0};
            const int tile=(static_cast<int>(hit.point.x+50000.0)+static_cast<int>(hit.point.y+50000.0))&1;
            hit.texture=kGround[tile];
            hit.found=true;
        }
    }
    for (const Sphere& sphere : kSpheres) {
        const Vec3 relative=subtract(sphere.center,origin);
        const double inverseDirection=1.0/dot(direction,direction);
        const double projection=dot(relative,direction)*inverseDirection;
        const double constant=(sphere.radius*sphere.radius-dot(relative,relative))*inverseDirection;
        const double discriminant=constant+projection*projection;
        if (discriminant>0.0) {
            const double root=std::sqrt(discriminant);
            double candidate=projection-root;
            if (candidate<kEpsilon) candidate=projection+root;
            if (candidate>kEpsilon && (candidate<hit.distance || hit.distance<0.0)) {
                hit.distance=candidate;
                const Vec3 local=multiply(direction,candidate);
                hit.normal=subtract(local,relative);
                hit.point=add(local,origin);
                hit.texture=sphere.texture;
                hit.found=true;
            }
        }
    }
    return hit;
}

Vec3 trace(Context& context, Vec3 origin, Vec3 direction, int recursion) {
    Vec3 color{0.0,0.0,0.0};
    if (recursion<=0) return color;
    const bool useDistribution=(kMaxRecursion-recursion)<kDistributionLevels;
    const Hit hit=intersect(origin,direction);
    if (hit.distance>kEpsilon) {
        const Vec3 lightDirection=subtract(kLight,hit.point);
        const double lightDot=dot(lightDirection,hit.normal);
        double lightAmount=0.0;
        if (lightDot>0.0) {
            int visible=0;
            if (useDistribution) {
                const double radiusScale=0.4/length(lightDirection);
                for (int i=0;i<context.distribution;i++) {
                    const Vec3 offset=distributedVector(context,lightDirection,radiusScale,radiusScale);
                    const Hit shadow=intersect(hit.point,add(lightDirection,offset));
                    if (shadow.distance<kEpsilon || shadow.distance>1.0) ++visible;
                }
            } else {
                const Hit shadow=intersect(hit.point,lightDirection);
                if (shadow.distance<kEpsilon || shadow.distance>1.0) visible=context.distribution;
            }
            if (visible>0) {
                const double norm=dot(hit.normal,hit.normal)*dot(lightDirection,lightDirection);
                lightAmount=(lightDot/std::sqrt(norm))*hit.texture.diffuse*
                    static_cast<double>(visible)/context.distribution;
            }
        }
        color=multiply(hit.texture.color,0.3+lightAmount);
        if (hit.texture.reflect>kEpsilon) {
            const Vec3 reflected=reflect(direction,hit.normal);
            Vec3 reflectedColor{0.0,0.0,0.0};
            if (useDistribution && hit.texture.roughness>kEpsilon) {
                for (int i=0;i<context.distribution;i++) {
                    const Vec3 offset=distributedVector(context,reflected,hit.texture.roughness,hit.texture.roughness);
                    reflectedColor=add(reflectedColor,trace(context,hit.point,add(reflected,offset),recursion-1));
                }
                reflectedColor=multiply(reflectedColor,1.0/context.distribution);
            } else {
                reflectedColor=trace(context,hit.point,reflected,recursion-1);
            }
            color=add(color,multiply(reflectedColor,hit.texture.reflect));
        }
    } else {
        const double horizontal=std::sqrt(direction.x*direction.x+direction.y*direction.y);
        const double blend=horizontal>0.0
            ? std::atan(std::fabs(direction.z)/horizontal)*0.63661977
            : 1.0;
        color=add(multiply(kSkyZenith,blend),multiply(kSkyHorizon,1.0-blend));
    }
    if (color.x>1.0) color.x=1.0;
    if (color.y>1.0) color.y=1.0;
    if (color.z>1.0) color.z=1.0;
    return color;
}
} // namespace

extern "C" std::int64_t freebench_distray(const std::int64_t* input,
        std::size_t input_length, std::uint8_t* output, std::size_t output_capacity) {
    if (input==nullptr || input_length!=3) return -1;
    if (input[0]<1 || input[0]>5 || input[1]<0 || input[1]>=kWidth ||
        input[2]<0 || input[2]>=kHeight) return -1;
    if (output==nullptr || output_capacity<3) return -2;
    Context context{static_cast<int>(input[0]),UINT32_C(0x52462467)};
    const double scaleX=(static_cast<double>(input[1])-kWidth/2)/kWidth;
    const double scaleZ=(kHeight/2-static_cast<double>(input[2]))/kHeight;
    const Vec3 direction{
        kCameraRight.x*scaleX+kCameraDirection.x+kCameraUp.x*scaleZ,
        kCameraRight.y*scaleX+kCameraDirection.y+kCameraUp.y*scaleZ,
        kCameraRight.z*scaleX+kCameraDirection.z+kCameraUp.z*scaleZ
    };
    Vec3 pixelColor{0.0,0.0,0.0};
    for (int ray=0;ray<context.distribution;ray++) {
        const Vec3 offset=distributedVector(context,direction,0.5/kWidth,0.5/kHeight);
        pixelColor=add(pixelColor,trace(context,kCamera,add(direction,offset),kMaxRecursion));
    }
    pixelColor=multiply(pixelColor,1.0/context.distribution);
    output[0]=static_cast<std::uint8_t>(static_cast<int>(pixelColor.x*255.0)&0xfe);
    output[1]=static_cast<std::uint8_t>(static_cast<int>(pixelColor.y*255.0)&0xfe);
    output[2]=static_cast<std::uint8_t>(static_cast<int>(pixelColor.z*255.0)&0xfe);
    return 3;
}
