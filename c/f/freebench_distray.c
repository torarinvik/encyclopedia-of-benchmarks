/*
 * Independent bounded FreeBench/distray profile.
 * Scene and ray-tracing behavior are attributed to Marcus Geelnard;
 * benchmarkification is attributed to Peter Rundberg (biff@ce.chalmers.se).
 * The pinned upstream source carries no explicit license grant; this file
 * is an independent implementation and does not infer or extend a license.
 */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { DISTRAY_WIDTH = 640, DISTRAY_HEIGHT = 480, DISTRAY_MAX_DISTRIB = 5 };
static const double EPSILON = 1.0e-5;
static const double MAX_T = 1.0e5;
static const int MAX_REC = 6;
static const int DIST_LEVELS = 3;
static const double AMBIENT = 0.3;
static const double LIGHT_RADIUS = 0.4;

typedef struct { double x, y, z; } Vec3;
typedef struct { Vec3 color; double diffuse, reflect, roughness; } Texture;
typedef struct { Vec3 center; double radius; Texture texture; } Sphere;
typedef struct { double t; Vec3 point, normal; Texture texture; int hit; } Hit;
typedef struct { int distribution; uint32_t random_state; } TraceContext;

static const Sphere SPHERES[4] = {
    {{0.0, 4.0, 1.0}, 1.0, {{1.0, 0.4, 0.0}, 0.4, 0.8, 0.02}},
    {{-1.0, 3.0, 0.4}, 0.4, {{0.5, 0.3, 1.0}, 0.5, 0.9, 0.01}},
    {{-0.3, 1.0, 0.4}, 0.4, {{0.1, 0.95, 0.2}, 0.6, 0.8, 0.01}},
    {{1.0, 2.0, 0.4}, 0.4, {{0.86, 0.83, 0.0}, 0.7, 0.6, 0.01}}
};
static const Texture GROUND[2] = {
    {{0.0, 0.1, 0.5}, 0.8, 0.44, 0.02},
    {{0.6, 1.0, 0.5}, 0.8, 0.44, 0.01}
};
static const Vec3 LIGHT = {-3.0, 1.0, 5.0};
static const Vec3 CAMERA = {1.5, -1.4, 1.2};
static const Vec3 CAMERA_RIGHT = {3.0, 1.0, 0.0};
static const Vec3 CAMERA_DIR = {-1.0, 3.0, 0.0};
static const Vec3 CAMERA_UP = {0.0, 0.0, 2.3717};
static const Vec3 SKY_HORIZON = {0.5, 0.3, 0.7};
static const Vec3 SKY_ZENITH = {0.0, 0.0, 0.2};

static Vec3 add(Vec3 a, Vec3 b) { return (Vec3){a.x+b.x, a.y+b.y, a.z+b.z}; }
static Vec3 sub(Vec3 a, Vec3 b) { return (Vec3){a.x-b.x, a.y-b.y, a.z-b.z}; }
static Vec3 scale(Vec3 a, double s) { return (Vec3){a.x*s, a.y*s, a.z*s}; }
static double dot(Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }
static double length(Vec3 a) { return sqrt(dot(a, a)); }

static double jitter(TraceContext *context) {
    context->random_state =
        (uint32_t)((UINT64_C(1103515245) * context->random_state + UINT64_C(12345)) & UINT64_C(0x7fffffff));
    return 1.0 - ((double)context->random_state / (double)UINT32_C(0x3fffffff));
}

static Vec3 distributed_vector(TraceContext *context, Vec3 normal, double sa, double sb) {
    Vec3 a, b;
    if (fabs(normal.z) > EPSILON) {
        a = (Vec3){normal.y*normal.z, -normal.x*normal.z, 0.0};
        b = (Vec3){a.y*normal.z, -a.x*normal.z, a.x*normal.y-a.y*normal.x};
    } else {
        a = (Vec3){normal.y, -normal.x, 0.0};
        b = (Vec3){0.0, 0.0, 1.0};
    }
    double normal_length = length(normal);
    a = scale(a, sa*(normal_length/length(a))*jitter(context));
    b = scale(b, sb*(normal_length/length(b))*jitter(context));
    return add(a, b);
}

static Vec3 reflected_vector(Vec3 incident, Vec3 normal) {
    double a = -2.0*dot(incident, normal)/dot(normal, normal);
    return add(incident, scale(normal, a));
}

static Hit intersect_objects(Vec3 origin, Vec3 direction) {
    Hit hit = {.t = -1.0, .hit = 0};
    if (fabs(direction.z) > EPSILON) {
        double candidate = -origin.z/direction.z;
        if (candidate > EPSILON && candidate < MAX_T) {
            hit.t = candidate;
            hit.point = add(origin, scale(direction, candidate));
            hit.normal = (Vec3){0.0, 0.0, 1.0};
            int tile = ((int)(hit.point.x+50000.0) + (int)(hit.point.y+50000.0)) & 1;
            hit.texture = GROUND[tile];
            hit.hit = 1;
        }
    }
    for (int index = 0; index < 4; ++index) {
        Vec3 relative_center = sub(SPHERES[index].center, origin);
        double inverse_direction_length_squared = 1.0/dot(direction, direction);
        double projection = dot(relative_center, direction)*inverse_direction_length_squared;
        double constant = (SPHERES[index].radius*SPHERES[index].radius -
                           dot(relative_center, relative_center))*inverse_direction_length_squared;
        double discriminant = constant + projection*projection;
        if (discriminant > 0.0) {
            double root = sqrt(discriminant);
            double candidate = projection-root;
            if (candidate < EPSILON) candidate = projection+root;
            if (candidate > EPSILON && (candidate < hit.t || hit.t < 0.0)) {
                hit.t = candidate;
                Vec3 local_point = scale(direction, candidate);
                hit.normal = sub(local_point, relative_center);
                hit.point = add(local_point, origin);
                hit.texture = SPHERES[index].texture;
                hit.hit = 1;
            }
        }
    }
    return hit;
}

static Vec3 trace_line(TraceContext *context, Vec3 origin, Vec3 direction, int recursion) {
    Vec3 color = {0.0, 0.0, 0.0};
    if (recursion <= 0) return color;
    int use_distribution = (MAX_REC-recursion) < DIST_LEVELS;
    Hit hit = intersect_objects(origin, direction);
    if (hit.t > EPSILON) {
        Vec3 light_direction = sub(LIGHT, hit.point);
        double light_dot_normal = dot(light_direction, hit.normal);
        double light_intensity = 0.0;
        if (light_dot_normal > 0.0) {
            int shadow_count = 0;
            if (use_distribution) {
                double radius_scale = LIGHT_RADIUS/length(light_direction);
                for (int ray = 0; ray < context->distribution; ++ray) {
                    Vec3 offset = distributed_vector(context, light_direction, radius_scale, radius_scale);
                    Hit shadow = intersect_objects(hit.point, add(light_direction, offset));
                    if (shadow.t < EPSILON || shadow.t > 1.0) shadow_count += 1;
                }
            } else {
                Hit shadow = intersect_objects(hit.point, light_direction);
                if (shadow.t < EPSILON || shadow.t > 1.0) shadow_count = context->distribution;
            }
            if (shadow_count > 0) {
                double normalization = dot(hit.normal, hit.normal)*dot(light_direction, light_direction);
                light_intensity = (light_dot_normal/sqrt(normalization))*hit.texture.diffuse*
                    (double)shadow_count/(double)context->distribution;
            }
        }
        color = scale(hit.texture.color, AMBIENT+light_intensity);
        if (hit.texture.reflect > EPSILON) {
            Vec3 reflected = reflected_vector(direction, hit.normal);
            Vec3 reflected_color = {0.0, 0.0, 0.0};
            if (use_distribution && hit.texture.roughness > EPSILON) {
                for (int ray = 0; ray < context->distribution; ++ray) {
                    Vec3 offset = distributed_vector(context, reflected,
                        hit.texture.roughness, hit.texture.roughness);
                    reflected_color = add(reflected_color,
                        trace_line(context, hit.point, add(reflected, offset), recursion-1));
                }
                reflected_color = scale(reflected_color, 1.0/(double)context->distribution);
            } else {
                reflected_color = trace_line(context, hit.point, reflected, recursion-1);
            }
            color = add(color, scale(reflected_color, hit.texture.reflect));
        }
    } else {
        double horizontal = sqrt(direction.x*direction.x+direction.y*direction.y);
        double blend = horizontal > 0.0
            ? atan(fabs(direction.z)/horizontal)*0.63661977
            : 1.0;
        color = add(scale(SKY_ZENITH, blend), scale(SKY_HORIZON, 1.0-blend));
    }
    if (color.x > 1.0) color.x = 1.0;
    if (color.y > 1.0) color.y = 1.0;
    if (color.z > 1.0) color.z = 1.0;
    return color;
}

int64_t freebench_distray(const int64_t *input, size_t input_length,
                          uint8_t *output, size_t output_capacity) {
    if (input == NULL || input_length != 3u) return -1;
    if (input[0] < 1 || input[0] > DISTRAY_MAX_DISTRIB ||
        input[1] < 0 || input[1] >= DISTRAY_WIDTH ||
        input[2] < 0 || input[2] >= DISTRAY_HEIGHT) return -1;
    if (output == NULL || output_capacity < 3u) return -2;

    TraceContext context = {(int)input[0], UINT32_C(0x52462467)};
    double scale_x = ((double)input[1]-(double)(DISTRAY_WIDTH/2))/(double)DISTRAY_WIDTH;
    double scale_z = ((double)(DISTRAY_HEIGHT/2)-(double)input[2])/(double)DISTRAY_HEIGHT;
    Vec3 direction = {
        CAMERA_RIGHT.x*scale_x + CAMERA_DIR.x + CAMERA_UP.x*scale_z,
        CAMERA_RIGHT.y*scale_x + CAMERA_DIR.y + CAMERA_UP.y*scale_z,
        CAMERA_RIGHT.z*scale_x + CAMERA_DIR.z + CAMERA_UP.z*scale_z
    };
    Vec3 pixel_color = {0.0, 0.0, 0.0};
    for (int ray = 0; ray < context.distribution; ++ray) {
        Vec3 offset = distributed_vector(&context, direction,
            0.5/(double)DISTRAY_WIDTH, 0.5/(double)DISTRAY_HEIGHT);
        pixel_color = add(pixel_color,
            trace_line(&context, CAMERA, add(direction, offset), MAX_REC));
    }
    pixel_color = scale(pixel_color, 1.0/(double)context.distribution);
    output[0] = (uint8_t)((int)(pixel_color.x*255.0) & 0xfe);
    output[1] = (uint8_t)((int)(pixel_color.y*255.0) & 0xfe);
    output[2] = (uint8_t)((int)(pixel_color.z*255.0) & 0xfe);
    return 3;
}
