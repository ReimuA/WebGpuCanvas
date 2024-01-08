const resolution:  vec2<f32> = vec2(1920, 1080);

@group(0) @binding(0) var<uniform> time: f32;

@fragment
fn main(@builtin(position) coordinates: vec4<f32>) -> @location(0) vec4<f32> {
  return vec4(coordinates.x / resolution.x, coordinates.y / resolution.y, abs(cos((time * 10) / 1920)), 1.0);
}
