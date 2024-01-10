import type { Vector3 } from "./Vector3";

export function createCameraKeyboardListener(eye: Vector3, viewplan: Vector3): (evt: KeyboardEvent) => void {
    return (evt: KeyboardEvent) => {
            if (evt.key == "q")
                //eye.x -= 0.1
                viewplan.x -= 0.1
            if (evt.key == "d")
                //eye.x += 0.1;
                viewplan.x += 0.1
            if (evt.key == "z")
                //eye.z -= 0.1;
                viewplan.y -= 0.1
            if (evt.key == "s")
                //eye.z += 0.1;
                viewplan.y += 0.1
    }
}