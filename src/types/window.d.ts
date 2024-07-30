
/**
 * This file, `types/window.d.ts`, is a TypeScript declaration file. It exists to help
 * our TypeScript code understand custom properties that we add to the global `window`
 * object. Here's a simple breakdown of why it's important and how it works:
 *
 * - **Why It Exists**: In our project, we have a Ruby Rack application on the backend
 *   and a Vue application on the frontend. The Ruby Rack app passes data to the Vue app
 *   by embedding it directly into a `<script>` tag within the HTML header template.
 *   This script adds custom properties to the `window` object, which the Vue app can
 *   then access to get the data it needs.
 *
 * - **What It Does**: Normally, TypeScript doesn't know about any custom properties we
 *   add to `window` because it relies on a standard set of type definitions for
 *   JavaScript objects. This file extends the existing `Window` interface to include
 *   our custom properties, so TypeScript can understand and work with them without
 *   showing errors.
 *
 * - **How It Works**: By declaring an interface with the same name as an existing one
 *   (`Window` in this case) and adding our custom properties to it, TypeScript performs
 *   what's called "declaration merging". This means it combines our custom definitions
 *   with the existing `Window` interface. After we do this, whenever we access
 *   something like `window.myCustomProperty`, TypeScript knows what it is and that it's
 *   okay to use it.
 *
 * - **Example**: If our Ruby Rack app passes a property called `shrimp` to the Vue app,
 *   we would add it to this file like so:
 *   ```typescript
 *   interface Window {
 *     shrimp: any; // Replace `any` with a more specific type if you know what
 *                  // structure `shrimp` will have
 *   }
 *   ```
 *   Now, TypeScript knows about `window.shrimp`, and we can access it in our Vue app
 *   without TypeScript complaining.
 *
 * This setup is crucial for ensuring that our frontend application can safely and
 * easily access the data passed from the backend, enhancing developer experience by
 * providing type safety and enabling better tooling support, like auto-completion in
 * IDEs.
 */

import { Cust, Plan } from './onetime';

declare global {
  interface Window {
    // Our CSRF token, to be used in POST requests to the backend
    shrimp?: string;
    custid?: string;
    cust?: Cust;
    available_plans?: Plan[];
    apitoken?: string;
    email?: string;
    customer_since?: string;
    vue_component_name?: string;
    deobfuscateEmails: () => void;
  }
}
