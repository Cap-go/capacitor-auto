import { WebPlugin } from '@capacitor/core';

import type {
  AutoAvailability,
  AutoMessageOptions,
  AutoPlugin,
  AutoTemplateOptions,
  PluginVersionResult,
} from './definitions';

export class AutoWeb extends WebPlugin implements AutoPlugin {
  private template?: AutoTemplateOptions;
  private lastMessage?: AutoMessageOptions;

  async isAvailable(): Promise<AutoAvailability> {
    return {
      available: false,
      connected: false,
      platform: 'web',
    };
  }

  async setRootTemplate(options: AutoTemplateOptions): Promise<void> {
    this.template = options;
  }

  async sendMessage(options: AutoMessageOptions): Promise<void> {
    this.lastMessage = options;
    await this.notifyListeners('messageReceived', {
      ...options,
      platform: 'web',
    });
  }

  async getPluginVersion(): Promise<PluginVersionResult> {
    return {
      version: 'web',
    };
  }

  getCurrentTemplate(): AutoTemplateOptions | undefined {
    return this.template;
  }

  getLastMessage(): AutoMessageOptions | undefined {
    return this.lastMessage;
  }
}
