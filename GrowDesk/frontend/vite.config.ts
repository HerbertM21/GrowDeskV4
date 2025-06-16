import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      // Corregir los alias de PrimeVue
      'primevue': 'primevue'
    },
    dedupe: ['vue']
  },
  server: {
    host: '0.0.0.0',
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8081',
        changeOrigin: true,
        secure: false,
        ws: true,
        configure: (proxy, _options) => {
          proxy.on('error', (err, _req, _res) => {
            console.log('proxy error', err);
          });
          proxy.on('proxyReq', (proxyReq, req, _res) => {
            console.log('Sending Request to the Target:', req.method, req.url);
          });
          proxy.on('proxyRes', (proxyRes, req, _res) => {
            console.log('Received Response from the Target:', proxyRes.statusCode, req.url);
          });
        },
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache'
        }
      }
    }
  },
  build: {
    minify: 'terser',
    terserOptions: {
      compress: {
        // Eliminar console.logs en producción
        drop_console: true,
        drop_debugger: true,
        pure_funcs: ['console.log', 'console.info', 'console.debug']
      },
      format: {
        // Eliminar comentarios
        comments: false
      },
      mangle: {
        // Ofuscar nombres de variables y funciones
        toplevel: true,
        safari10: true
      },
      // Ofuscar nombres de propiedades
      keep_classnames: false,
      keep_fnames: false
    },
    // Dividir el código en chunks más pequeños para mejor rendimiento
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor': ['vue', 'vue-router', 'pinia'],
          'charts': ['chart.js', 'vue-chartjs']
        },
        // Añadir hash a los nombres de archivos para evitar cacheo del navegador
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]'
      }
    },
    // Desactivar sourcemaps en producción
    sourcemap: false,
  },
}) 