import { WebPlugin } from '@capacitor/core';

import type {
  AutoAvailability,
  AutoMessageOptions,
  AutoPayload,
  AutoPlugin,
  AutoStateKeyOptions,
  AutoStateOptions,
  AutoStateResult,
  AutoTemplateOptions,
  PluginVersionResult,
} from './definitions';

export class AutoWeb extends WebPlugin implements AutoPlugin {
  private template?: AutoTemplateOptions;
  private lastMessage?: AutoMessageOptions;
  private state = new Map<string, AutoPayload>();
  private transientState = new Map<string, AutoPayload>();

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

  async setState(options: AutoStateOptions): Promise<void> {
    this.state.set(options.key, options.value);
    await this.notifyStateChanged(options.key, options.value, false);
  }

  async getState(options: AutoStateKeyOptions): Promise<AutoStateResult> {
    return this.stateResult(options.key, this.state.get(options.key));
  }

  async removeState(options: AutoStateKeyOptions): Promise<void> {
    this.state.delete(options.key);
    await this.notifyStateChanged(options.key, undefined, false);
  }

  async setTransientState(options: AutoStateOptions): Promise<void> {
    this.transientState.set(options.key, options.value);
    await this.notifyStateChanged(options.key, options.value, true);
  }

  async getTransientState(options: AutoStateKeyOptions): Promise<AutoStateResult> {
    return this.stateResult(options.key, this.transientState.get(options.key));
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

  private stateResult(key: string, value: AutoPayload | undefined): AutoStateResult {
    return value === undefined ? { key } : { key, value };
  }

  private async notifyStateChanged(key: string, value: AutoPayload | undefined, transient: boolean): Promise<void> {
    await this.notifyListeners('stateChanged', {
      ...this.stateResult(key, value),
      platform: 'web',
      transient,
    });
  }
}
