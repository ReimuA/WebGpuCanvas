import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vitest/config';
import vitePluginGlsl from 'vite-plugin-glsl'

export default defineConfig({
	plugins: [sveltekit(), vitePluginGlsl()],
	test: {
		include: ['src/**/*.{test,spec}.{js,ts}']
	}
});
