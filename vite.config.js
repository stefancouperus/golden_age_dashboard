import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  // Relative assets work under the repository path and a future custom domain.
  base: "./",
  build: { outDir: "dist" },
});
