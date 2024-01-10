export function createUniformBuffer(device: GPUDevice, content: Float32Array): GPUBuffer  {
    const uniformBuffer = device.createBuffer({
        size: content.byteLength,
        usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST
    });

    device.queue.writeBuffer(uniformBuffer, 0, content);
    return uniformBuffer;
}