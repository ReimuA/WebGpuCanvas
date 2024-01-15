// https://iquilezles.org/articles/warp/

const resolution:  vec2<f32> = vec2(1920, 1080);

@group(0) @binding(0) var<uniform> time: f32;
@group(0) @binding(1) var<uniform> viewplan: vec3<f32>;
@group(0) @binding(2) var<uniform> eye: vec3<f32>;

struct WarpData {
    s1: vec2<f32>,
    s2: vec2<f32>,
    sf: f32,
} 

fn rotate(p: vec2<f32>, angle: f32) -> vec2<f32> {
    var rotation = mat2x2(cos(angle), -sin(angle), sin(angle), cos(angle));

    return p * rotation;
}

fn palette(x: f32) -> vec3<f32> {
    var t = clamp(x, 0, 1);
    var a = vec3(0.500,0.500,-3.142);
    var b = vec3(1.098,1.028,0.500);
    var c = vec3(0.158,-0.372,1.000);
    var d = vec3(-0.262,0.498,0.667);
    return a+b*cos(6.28318*(c*t+d));
}

fn hash1(point: vec2<f32>) -> f32 {
    var p = 57.0 * fract(point * 1.4142135623);
    return fract(p.x * p.y);
}

// noise(x) -> y where y > -1 and y < 1
fn noise(x: vec2<f32>) -> f32 {
    var p = floor(x);
    var w = fract(x);
    var u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

    var a = hash1(p + vec2(0, 0));
    var b = hash1(p + vec2(1, 0));
    var c = hash1(p + vec2(0, 1));
    var d = hash1(p + vec2(1, 1));

    return -1.0 + 2.0 * (a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y);
}

fn fbm(x: vec2<f32>, h: f32) -> f32 {
    const angle = 0.8;
    var rot = mat2x2(cos(angle), -sin(angle), sin(angle), cos(angle)) * ((time + 40000) / 40000) ;

    var p = x;
    var g = exp2(-h);
    var f = 1.0;
    var a = 1.0;
    var t = 0.0;

    for (var i = 0; i < 12; i++) {
        t += a * noise(f * p);
        f *= 2.0;
        a *= g;
        p *= rot;
    }
    return t;
}

fn warp(point: vec2<f32>) -> WarpData {
    var warpData: WarpData;

    var x = point;

    var s1 = vec2(
        fbm(x + vec2(32, 12), 1),
        fbm(x + vec2(-23, 51.3), 1)
    );

    var s2 = vec2(
        fbm(s1 * 4 + vec2(1245.7, 19.2), 1),
        fbm(s1 * 4 + vec2(0.3, 42.8), 1)
    );

    var p = fbm(x + 4 * s2, 1);

    warpData.s1 = s1;
    warpData.s2 = s2;
    warpData.sf = p;
    return warpData;
}

fn render(p: vec2<f32>) -> vec3<f32> {
    var res = warp(p);

/*     var c1 = vec3(palette(length(res.s1) * 0.5)) * 0.9;
    var c2 = vec3(palette(length(res.s2) * 0.75));
    var c3 = vec3(palette((res.sf + 1) / 2)); */
 
    return palette(mix(length(res.s1) / 2, length(res.s2), (res.sf + 1) / 2));
}

@fragment
fn main(@builtin(position) coordinates: vec4<f32>) -> @location(0) vec4<f32> {
    var p = (2.0 * coordinates.xy - resolution.xy) / resolution.y;
    p += time / 50;
    p = rotate(p, time / 50);

    return vec4(render(p), 1.0);
}
