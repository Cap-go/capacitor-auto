import { registerPlugin } from '@capacitor/core';

import type { AutoPlugin } from './definitions';

const Auto = registerPlugin<AutoPlugin>('Auto', {
  web: () => import('./web').then((m) => new m.AutoWeb()),
});

export * from './definitions';
export { Auto };
