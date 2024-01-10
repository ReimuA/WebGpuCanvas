<script lang="ts">
	import { onMount } from 'svelte';
	import '../app.css';

	import raymarchingShader from '$lib/shaders/raymarch.frag.wgsl';
	import vertexShader from '$lib/shaders/triangle.vert.wgsl';
	import { createClock } from '$lib/clock';
	import { createUniformBuffer } from '$lib/binding';
	import { Vector3ToArray } from '$lib/Vector3';
	import { createCameraKeyboardListener } from '$lib/camera';

	let clock = createClock();

	let canvas!: HTMLCanvasElement;
	let context: GPUCanvasContext | null;
	let device: GPUDevice;

	let eye = { x: 4.9, y: 4, z: 4.9 };
	let viewplan = { x: 0.0, y: -0.75, z: -0.0 };

	let keyboardListener = createCameraKeyboardListener(eye, viewplan);

	onMount(async () => {
		canvas.width = window.innerWidth;
		canvas.height = window.innerHeight;

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

		var bindGroupLayoutEntries = [0, 1, 2].map<GPUBindGroupLayoutEntry>((binding) => ({
			binding,
			visibility: GPUShaderStage.FRAGMENT,
			buffer: {
				type: 'uniform'
			}
		}));

		const bindGroupLayout = device.createBindGroupLayout({ entries: bindGroupLayoutEntries });

		const timeUniform = createUniformBuffer(device, new Float32Array([0]));
		const eyeUniform = createUniformBuffer(device, Vector3ToArray(eye));
		const viewPlanUniform = createUniformBuffer(device, Vector3ToArray(viewplan));

		const bindGroup = device.createBindGroup({
			layout: bindGroupLayout,
			entries: [timeUniform, viewPlanUniform, eyeUniform].map((buffer, i) => ({
				binding: i,
				resource: { buffer }
			}))
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

			device.queue.writeBuffer(timeUniform, 0, new Float32Array([clock.timeElapsed() / 1000]));
			device.queue.writeBuffer(eyeUniform, 0, Vector3ToArray(eye));
			device.queue.writeBuffer(viewPlanUniform, 0, Vector3ToArray(viewplan));

			const passEncoder = commandEncoder.beginRenderPass(renderPassDescriptor);
			passEncoder.setPipeline(pipeline);
			passEncoder.setBindGroup(0, bindGroup);
			passEncoder.draw(6);
			passEncoder.end();

			device.queue.submit([commandEncoder.finish()]);
			requestAnimationFrame(frame);
		}

		clock.reset();
		requestAnimationFrame(frame);
	});
</script>

<canvas bind:this={canvas} class="w-screen h-screen"></canvas>
<svelte:window on:keydown={keyboardListener} />
