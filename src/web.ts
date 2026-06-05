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

const ROOT_TEMPLATE_STATE_KEY = '__capgo_auto_root_template';

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
    const key = this.assertValidKey(options);
    const value = this.assertValidPayload(options);
    this.state.set(key, value);
    await this.notifyStateChanged(key, value, false);
  }

  async getState(options: AutoStateKeyOptions): Promise<AutoStateResult> {
    const key = this.assertValidKey(options);
    return this.stateResult(key, this.state.get(key));
  }

  async removeState(options: AutoStateKeyOptions): Promise<void> {
    const key = this.assertValidKey(options);
    this.state.delete(key);
    await this.notifyStateChanged(key, undefined, false);
  }

  async setTransientState(options: AutoStateOptions): Promise<void> {
    const key = this.assertValidKey(options);
    const value = this.assertValidPayload(options);
    this.transientState.set(key, value);
    await this.notifyStateChanged(key, value, true);
  }

  async getTransientState(options: AutoStateKeyOptions): Promise<AutoStateResult> {
    const key = this.assertValidKey(options);
    return this.stateResult(key, this.transientState.get(key));
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
    return value === undefined ? { key } : { key, value: this.clonePayload(value) };
  }

  private async notifyStateChanged(key: string, value: AutoPayload | undefined, transient: boolean): Promise<void> {
    await this.notifyListeners('stateChanged', {
      ...this.stateResult(key, value),
      platform: 'web',
      transient,
    });
  }

  private assertValidKey(options: AutoStateKeyOptions): string {
    if (options === null || typeof options !== 'object') {
      throw new Error('State options must be an object');
    }

    const key = (options as { key?: unknown }).key;
    if (typeof key !== 'string' || key.length === 0) {
      throw new Error('State key must be a non-empty string');
    }

    if (key === ROOT_TEMPLATE_STATE_KEY) {
      throw new Error(`State key is reserved: ${ROOT_TEMPLATE_STATE_KEY}`);
    }

    return key;
  }

  private assertValidPayload(options: AutoStateOptions): AutoPayload {
    if (options === null || typeof options !== 'object') {
      throw new Error('State options must be an object');
    }

    const value = (options as { value?: unknown }).value;
    if (value === null || Array.isArray(value) || typeof value !== 'object') {
      throw new Error('State value must be a JSON object');
    }

    return this.clonePayload(value as AutoPayload);
  }

  private clonePayload(value: AutoPayload): AutoPayload {
    return JSON.parse(JSON.stringify(value)) as AutoPayload;
  }
}
