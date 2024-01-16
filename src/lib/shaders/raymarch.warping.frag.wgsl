const resolution:  vec2<f32> = vec2(1920, 1080);

const sunpos = vec3(0, 0, 240);
const sunradius = 64.;

// TimeElapsed, as second
@group(0) @binding(0) var<uniform> time: f32;
@group(0) @binding(1) var<uniform> viewplan: vec3<f32>;
@group(0) @binding(2) var<uniform> eye: vec3<f32>;


struct WarpData {
    s1: vec2<f32>,
    s2: vec2<f32>,
    sf: f32,
} 

struct WarpData3d {
    s1: vec3<f32>,
    s2: vec3<f32>,
    sf: f32,
}

fn rotate(p: vec2<f32>, angle: f32) -> vec2<f32> {
    var rotation = mat2x2(cos(angle), -sin(angle), sin(angle), cos(angle));

    return p * rotation;
}

fn palette(x: f32) -> vec3<f32> {
    var t = clamp(x, 0, 1);
    var a = vec3(0.500, 0.500, -3.142);
    var b = vec3(1.098, 1.028, 0.500);
    var c = vec3(0.158, -0.372, 1.000);
    var d = vec3(-0.262, 0.498, 0.667);
    return a + b * cos(6.28318 * (c * t + d));
}

fn hash2(point: vec2<f32>) -> f32 {
    var p = 57.0 * fract(point * 1.4142135623);
    return fract(p.x * p.y);
}

fn hash3(point: vec3<f32>) -> f32 {
    var p = 57.0 * fract(point * 1.4142135623);
    return fract(p.x * p.y * p.z);
}

// noise(x) -> y where y > -1 and y < 1
fn noise(x: vec2<f32>) -> f32 {
    var p = floor(x);
    var w = fract(x);
    var u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

    var a = hash2(p + vec2(0, 0));
    var b = hash2(p + vec2(1, 0));
    var c = hash2(p + vec2(0, 1));
    var d = hash2(p + vec2(1, 1));

    return -1.0 + 2.0 * (a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y);
}

fn mod289(x: vec4<f32>) -> vec4<f32> {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

fn perm(x: vec4<f32>) -> vec4<f32> {
    return mod289(((x * 34.0) + 1.0) * x);
}

fn noise3(p: vec3<f32>) -> f32 {
    var a = floor(p);
    var d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    var b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    var k1 = perm(b.xyxy);
    var k2 = perm(k1.xyxy + b.zzww);

    var c = k2 + a.zzzz;
    var k3 = perm(c);
    var k4 = perm(c + 1.0);

    var o1 = fract(k3 * (1.0 / 41.0));
    var o2 = fract(k4 * (1.0 / 41.0));

    var o3 = o2 * d.z + o1 * (1.0 - d.z);
    var o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}


fn fbm3(x: vec3<f32>, h: f32) -> f32 {
    var p = x;
    var g = exp2(-h);
    var f = 1.0;
    var a = 1.0;
    var t = 0.0;

    for (var i = 0; i < 12; i++) {
        t += a * noise3(f * p);
        f *= 2.0;
        a *= g;
        p = rotateX(p, 0.4);
        p = rotateY(p, 0.1);
        p = rotateZ(p, 0.7);
    }
    return t;
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

fn warp3d(point: vec3<f32>) -> WarpData3d {
    var warpData: WarpData3d;

    var x = point;

    var s1 = vec3(
        fbm3(x + vec3(32, 12, 2), 1),
        fbm3(x + vec3(-23, 51.3, -4), 1),
        fbm3(x + vec3(-3, 251.3, -14), 1)
    );

    var s2 = vec3(
        fbm3(s1 * 3 + vec3(1245.7, 19.2, 14), 1),
        fbm3(s1 * 3 + vec3(0.3, 42.8, 4), 1),
        fbm3(s1 * 3 + vec3(12.3, 2.8, 14), 1)
    );

    var p = fbm3(x + s2, 1);

    warpData.s1 = s1;
    warpData.s2 = s2;
    warpData.sf = p;
    return warpData;
}

fn c01(p: f32) -> f32 {
    return clamp(p, 0.0, 1.0);
}

fn rotateX(p: vec3<f32>, angle: f32) -> vec3<f32> {
    return p * mat3x3<f32>(1.0, 0.0, 0.0, 0.0, cos(angle), -sin(angle), 0.0, sin(angle), cos(angle));
}

fn rotateY(p: vec3<f32>, angle: f32) -> vec3<f32> {
    return p * mat3x3<f32>(cos(angle), 0.0, sin(angle), 0.0, 1.0, 0.0, -sin(angle), 0.0, cos(angle));
}

fn rotateZ(p: vec3<f32>, angle: f32) -> vec3<f32> {
    return  p * mat3x3<f32>(cos(angle), -sin(angle), 0.0, sin(angle), cos(angle), 0.0, 0.0, 0.0, 1.0);
}

fn sdfSphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sdf(p: vec3<f32>) -> f32 {
    return sdfSphere(p - sunpos, sunradius);
}

fn calcNormal(pos: vec3<f32>) -> vec3<f32> {
    let e: vec2<f32> = vec2(1.0, -1.0) * 0.5773 * 0.0005;
    return normalize(
        e.xyy * sdf(pos + e.xyy) + e.yyx * sdf(pos + e.yyx) + e.yxy * sdf(pos + e.yxy) + e.xxx * sdf(pos + e.xxx)
    );
}

struct RaymarchData {
    distance: f32,
    minDistance: f32,
}

fn raymarch(rayOrigin: vec3<f32>, rayDirection: vec3<f32>) -> RaymarchData {
    var distance = 0.0;
    let maxDistance = 400.0;
    let minHitDistance = 0.001;
    var rData: RaymarchData;

    rData.minDistance = 5000000;

    for (var i = 0; i < 64; i++) {
        if distance > maxDistance {
			break;
        }

        let pos = rayOrigin + rayDirection * distance;

        let res = sdf(pos);

        rData.minDistance = min(rData.minDistance, res);

        if res < minHitDistance {
            rData.distance = distance + res;
            return rData;
        }

        distance += res;
    }

    rData.distance = -1;

    return rData;
}

fn render(rayOrigin: vec3<f32>, rayDirection: vec3<f32>) -> vec3<f32> {
    let rData = raymarch(rayOrigin, rayDirection);


    if rData.distance < 0. {
        var c = vec3(0.1, 0., 0);
        var r = smoothstep(0, 1.5, rData.minDistance);
        return mix(0.05 / c, vec3(0.), r);
    }

    var point = rayOrigin + rayDirection * rData.distance;
    var nPos = point - sunpos;
    nPos /= 10;
    nPos += vec3(1.1, -3, 12) * time / 60;
    nPos = rotateY(nPos, 1 * time / 80);
    var wd = warp3d(nPos);
    var idx = mix(length(wd.s1) / 4, length(wd.s2) / 3.6, (wd.sf));
    return palette(idx);
}

fn setCamera(ro: vec3<f32>, ta: vec3<f32>, cr: f32) -> mat3x3<f32> {
    let cw: vec3<f32> = normalize(ta - ro);
    let cp: vec3<f32> = vec3(0.0, 1.0, 0.0);
    let cu: vec3<f32> = normalize(cross(cw, cp));
    let cv: vec3<f32> = cross(cu, cw);

    return mat3x3<f32>(cu, cv, cw);
}

@fragment
fn main(@builtin(position) coordinates: vec4<f32>) -> @location(0) vec4<f32> {
    let camspeed: f32 = 1.25;
    let ta: vec3<f32> = vec3(viewplan);
    let ro: vec3<f32> = ta + eye;
    let ca = setCamera(ro, ta, 0.0);

    let st = -(2 * coordinates.xy - resolution.xy) / resolution.y;
    let fl = 2.5;
    let rd = normalize(ca * normalize(vec3(st, fl)));
    let color = render(ro, rd);

    let gammaCorrected = pow(color, vec3(1.0 / 2.6));
    return vec4(gammaCorrected, 1.0);
}
