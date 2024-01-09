const resolution:  vec2<f32> = vec2(1920, 1080);

@group(0) @binding(0) var<uniform> time: f32;

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

// Distance function
fn sdfSphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sdfPlane(p: vec3<f32>) -> f32 {
    return p.y;
}

fn sdf(p: vec3<f32>) -> f32 {
    var distance: f32 = sdfSphere(p, .8);
    return distance;
}

fn calcNormal(pos: vec3<f32>) -> vec3<f32> {
    let e: vec2<f32> = vec2(1.0, -1.0) * 0.5773 * 0.0005;
    return normalize(
        e.xyy * sdf(pos + e.xyy) + e.yyx * sdf(pos + e.yyx) + e.yxy * sdf(pos + e.yxy) + e.xxx * sdf(pos + e.xxx)
    );
}

fn normal(point: vec3<f32>) -> vec3<f32> {
    let smallStep = vec3(0.00001, 0., 0.);

    return normalize(
        vec3(
            sdf(point + smallStep.xyy) - sdf(point - smallStep.xyy),
            sdf(point + smallStep.yxy) - sdf(point - smallStep.yxy),
            sdf(point + smallStep.yyx) - sdf(point - smallStep.yyx)
        )
    );
}

fn directionalLight(
    rayDirection: vec3<f32>,
    normal: vec3<f32>,
    point: vec3<f32>,
    baseColor: vec3<f32>,
    lightDir: vec3<f32>,
    lightColor: vec3<f32>,
    shininess: f32
) -> vec3<f32> {
    var normalizedlightDir = normalize(lightDir);
    var hal = normalize(normalizedlightDir - rayDirection);
    var diffuse = dot(normal, normalizedlightDir);
    diffuse = c01(diffuse);
    diffuse *= ambientOcc(point, normal);
    diffuse *= shadow(point, normalizedlightDir, 0.02, 2.5);

    var pho = c01(pow(dot(normal, hal), shininess));
    var spe = pho * diffuse * 0.3;

    return baseColor * 2.2 * diffuse * lightColor + 5.0 * spe * lightColor * 0.4;
}

fn raymarch(rayOrigin: vec3<f32>, rayDirection: vec3<f32>) -> f32 {
    var distance = 0.0;
    let maxDistance = 50.0;
    let minHitDistance = 0.001;

    for (var i = 0; i < 256; i++) {
        if distance > maxDistance {
			break;
        }
        let pos = rayOrigin + rayDirection * distance;

        let res = sdf(pos);

        if res < minHitDistance {
            return distance + res;
        }

        distance += res;
    }

    return -1.0;
}

fn ambientOcc(point: vec3<f32>, normal: vec3<f32>) -> f32 {
    var occ = 0.0;
    var sca = 1.0;
    for (var i = 0; i < 5; i++) {
        var h = 0.01 + 0.12 * f32(i) / 4.0;
        var d = sdf(point + h * normal);
        occ += (h - d) * sca;
        sca *= 0.95;
        if occ > 0.35 {
			break;
        }
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0) * (0.5 + 0.5 * normal.y);
}

fn shadow(ro: vec3<f32>, rd: vec3<f32>, mint: f32, tmax: f32) -> f32 {
    var res = 1.0;
    var t = mint;
    for (var i = 0; i < 256; i++) {
        var h = sdf(ro + rd * t);

        if t > tmax {
            return res;
        }

        if h < 0.001 {
            return 0.0;
        }
        res = min(res, 18.0 * h / t);
        t += h;
    }
    return res;
}

fn render(rayOrigin: vec3<f32>, rayDirection: vec3<f32>) -> vec3<f32> {
    let distance = raymarch(rayOrigin, rayDirection);

    if distance < 0. {
        return vec3(0.);
    }

	var point = rayOrigin + rayDirection * distance;
    var normal = calcNormal(point);

    return directionalLight(
        rayDirection,
        normal,
        point,
        vec3(0.4, 0.2, 0.8),
        vec3(2.0, 2.0, 2.0),
        vec3(0.9294, 0.4275, 0.4),
        32.0
    );

    return abs(calcNormal(rayOrigin + rayDirection * distance));
}

fn setCamera(ro: vec3<f32>, ta: vec3<f32>, cr: f32) -> mat3x3<f32> {
    let cw: vec3<f32> = normalize(ta - ro);
    let cp: vec3<f32> = vec3(sin(cr), cos(cr), 0.0);
    let cu: vec3<f32> = normalize(cross(cw, cp));
    let cv: vec3<f32> = cross(cu, cw);
    return mat3x3<f32>(cu, cv, cw);
}

@fragment
fn main(@builtin(position) coordinates: vec4<f32>) -> @location(0) vec4<f32> {
  // camera magic
    let camspeed: f32 = .025;
    let ta: vec3<f32> = vec3(0.25, -0.75, -0.75);
    let ro: vec3<f32> = ta + vec3(4.9 * cos(time * camspeed), 3.0, 4.9 * sin(time * camspeed));

    let ca: mat3x3<f32> = setCamera(ro, ta, 0.0);
    let p = -(2.0 * coordinates.xy - resolution.xy) / resolution.y;
    let fl = 2.5;
    let rd = ca * normalize(vec3(p, fl));

    return vec4(render(ro, rd), 1.0);
}
