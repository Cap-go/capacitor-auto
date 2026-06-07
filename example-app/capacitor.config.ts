import type { CapacitorConfig } from '@capacitor/cli';

import pkg from './package.json';

const config: CapacitorConfig = {
  appId: 'app.capgo.auto.example',
  appName: 'Plugin Template Example',
  webDir: 'dist',
  plugins: {
    CapacitorUpdater: {
      appId: 'app.capgo.auto.example',
      autoUpdate: true,
      autoSplashscreen: true,
      directUpdate: 'always',
      defaultChannel: 'production',
      version: pkg.version,
    },
  },
};

export default config;
