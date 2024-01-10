export interface Vector3 {
    x: number,
    y: number,
    z: number,
}

export function Vector3ToArray(vector: Vector3): Float32Array {
    return new Float32Array([vector.x, vector.y, vector.z]);
}