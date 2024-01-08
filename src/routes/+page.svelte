<script lang="ts">
	import { onMount } from 'svelte';
	import '../app.css';

	import raymarchingShader from '$lib/shaders/raymarch.frag.wgsl';
	import vertexShader from '$lib/shaders/triangle.vert.wgsl';

	let frameCount: number = 0

	let canvas!: HTMLCanvasElement;
	let context: GPUCanvasContext | null;
	let device: GPUDevice;

	onMount(async () => {
		canvas.width = window.innerWidth
		canvas.height = window.innerHeight

		console.log(window.innerHeight)
		console.log(window.innerWidth)

		const adapter = await navigator.gpu.requestAdapter();
		device = await adapter!.requestDevice();
		context = canvas.getContext('webgpu');

		const devicePixelRatio = window.devicePixelRatio;
		canvas.width = canvas.clientWidth * devicePixelRatio;
		canvas.height = canvas.clientHeight * devicePixelRatio;
		const presentationFormat = navigator.gpu.getPreferredCanvasFormat();

		context?.configure({
			device,
			format: presentationFormat,
			alphaMode: 'premultiplied'
		});

		const vertexModule = device.createShaderModule({ code: vertexShader });
		const fragmentModule = device.createShaderModule({ code: raymarchingShader });

		const bindGroupLayout = device.createBindGroupLayout({
			entries: [
				{
					binding: 0,
					visibility: GPUShaderStage.FRAGMENT,
					buffer: {
						type: 'uniform'
					}
				}
			]
		});

		
		const uniformArray = new Float32Array([frameCount]);
		const uniformBuffer = device.createBuffer({
			size: uniformArray.byteLength,
			usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST
		});

		device.queue.writeBuffer(uniformBuffer, 0, uniformArray);

		// Create a bind group to pass the grid uniforms into the pipeline
		const bindGroup = device.createBindGroup({
			layout: bindGroupLayout,
			entries: [
				{
					binding: 0,
					resource: { buffer: uniformBuffer }
				}
			]
		});

		const pipelineLayout = device.createPipelineLayout({ bindGroupLayouts: [bindGroupLayout] });

		const pipeline = device.createRenderPipeline({
			layout: pipelineLayout,
			vertex: {
				module: vertexModule,
				entryPoint: 'main'
			},
			fragment: {
				module: fragmentModule,
				entryPoint: 'main',
				targets: [
					{
						format: presentationFormat
					}
				]
			}
		});

		function frame() {
			const commandEncoder = device.createCommandEncoder();
			const textureView = context!.getCurrentTexture().createView();

			const renderPassDescriptor: GPURenderPassDescriptor = {
				colorAttachments: [
					{
						view: textureView,
						clearValue: { r: 0.0, g: 0.0, b: 0.0, a: 1.0 },
						loadOp: 'clear',
						storeOp: 'store'
					}
				]
			};

			const uniformArray = new Float32Array([frameCount++]);
			device.queue.writeBuffer(uniformBuffer, 0, uniformArray);

			const passEncoder = commandEncoder.beginRenderPass(renderPassDescriptor);
			passEncoder.setPipeline(pipeline);
			passEncoder.setBindGroup(0, bindGroup);
			passEncoder.draw(6);
			passEncoder.end();

			device.queue.submit([commandEncoder.finish()]);
			requestAnimationFrame(frame);
		}

		requestAnimationFrame(frame);
	});
</script>

<canvas bind:this={canvas} class="w-screen h-screen"></canvas>
