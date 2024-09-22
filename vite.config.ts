import { defineConfig } from 'vite'
//import { createHtmlPlugin } from 'vite-plugin-html'
import vue from '@vitejs/plugin-vue'
import path from 'path'

// Remember, for security reasons, only variables prefixed with VITE_ are
// available here to prevent accidental exposure of sensitive
// environment variables to the client-side code.
const apiBaseUrl = process.env.VITE_API_BASE_URL || 'https://dev.onetimesecret.com';

export default defineConfig({
  root: "./src",

  plugins: [
    vue({
      template: {
        compilerOptions: {
          // Be cool and chill about 3rd party components. Alternatvely can use
          // `app.config.compilerOptions.isCustomElement = tag => tag.startsWith('altcha-')`
          // in main.ts.
          isCustomElement: tag => tag.includes('altcha-')

        }
      }
    }),
    // Uncomment and adjust the createHtmlPlugin configuration as needed
    // TODO: Doesn't add the preload <link> to the output index.html
    //       but it does process the html b/c minify: true works.
    //       Might be handy for some use cases. Leaving for now.
    // Corresponds with the following in the input index.html:
    //
    //  <%~ preloadFonts.map(font => `<link rel="preload" href="${font}" as="font" type="font/woff2">`) %>
    //
    //createHtmlPlugin({
    //  minify: false,
    //  entry: 'main.ts',
    //  template: 'index.html',
    //  inject: {
    //    data: {
    //      preloadFonts: [
    //        '/dist/assets/ZillaSlab-Regular.woff2',
    //        '/dist/assets/ZillaSlab-Regular.woff',
    //        '/dist/assets/ZillaSlab-Bold.woff2',
    //        '/dist/assets/ZillaSlab-Bold.woff',
    //      ]
    //    }
    //  }
    //})
  ],

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),

      // Resolves browser console warning:
      //
      //    [Vue warn]: Component provided template option but runtime compilation is
      //    not supported in this build of Vue. Configure your bundler to alias "vue"
      //    to "vue/dist/vue.esm-bundler.js".
      //
      'vue': 'vue/dist/vue.esm-bundler.js'
    }
  },

  assetsInclude: ['assets/fonts/**/*.woff', 'assets/fonts/**/*.woff2'], // Include font files
  base: '/dist',

  publicDir: 'public/web',

  // be simpler and more efficient.
  build: {
    outDir: '../public/web/dist',

    // It's important in staging to keep the previous files around during and
    // for an hour after fly deploy: during the deploy so that requests coming
    // in going to one or the other machines can continue serving the previous
    // version, and for an hour after the deploy for the redis cache to expire
    // (or be manually deleted). The key is template:global:vite_assets in db 0.
    emptyOutDir: false,

    // Code Splitting vs Combined Files
    //
    // Code Splitting:
    // Advantages:
    // 1. Improved Initial Load Time: Only the necessary code for the initial page
    // is loaded, with additional code loaded as needed.
    // 2. Better Caching: Smaller, more granular files can be cached more
    // effectively. Changes in one part of the application only require updating
    // the corresponding file.
    // 3. Parallel Loading: Modern browsers can download multiple files in
    // parallel, speeding up the overall loading process.
    //
    // Disadvantages:
    // 1. Increased Complexity: Managing multiple files can be more complex,
    // especially with dependencies and ensuring correct load order.
    // 2. More HTTP Requests: More files mean more HTTP requests, which can be a
    // performance bottleneck on slower networks.
    //
    // Combined Files:
    // Advantages:
    // 1. Simplicity: A single file is easier to manage and deploy, with no
    // concerns about missing files or incorrect load orders.
    // 2. Fewer HTTP Requests: Combining everything into a single file reduces the
    // number of HTTP requests, beneficial for performance on slower networks.
    //
    // Disadvantages:
    // 1. Longer Initial Load Time: The entire application needs to be downloaded
    // before it can be used, increasing initial load time.
    // 2. Inefficient Caching: Any change in the application requires the entire
    // bundle to be re-downloaded.
    //
    // Conclusion:
    // The conventional approach in modern web development is to use code
    // splitting for better performance and caching. However, the best approach
    // depends on the specific use case. For larger applications, code splitting
    // is usually preferred, while for smaller applications, combining files might
    manifest: true,
    rollupOptions: {
      input: {
        main: 'src/main.ts', // Explicitly define the entry point here
      },
      //output: {
      //  manualChunks: undefined, // Disable code splitting
      //  entryFileNames: 'assets/[name].[hash].js', // Single JS file
      //  chunkFileNames: 'assets/[name].[hash].js', // Single JS file
      //  assetFileNames: 'assets/[name].[hash].[ext]', // Single CSS file
      //}
    },

    // https://guybedford.com/es-module-preloading-integrity
    // https://github.com/vitejs/vite/issues/5120#issuecomment-971952210
    modulePreload: {
      polyfill: true,
    },
  },

  server: {
    origin: apiBaseUrl,
  },

  // Add this section to explicitly include dependencies for pre-bundling
  optimizeDeps: {
    include: [
      // List dependencies that you want to pre-bundle here
      // Example: 'vue', 'axios'
      //'vue'
    ]
  },

  define: {
    'process.env.API_BASE_URL': JSON.stringify(apiBaseUrl),
  },
})
