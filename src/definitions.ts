import type { PluginListenerHandle } from '@capacitor/core';

export type AutoPlatform = 'ios' | 'android' | 'web';

export type AutoPayloadValue =
  | null
  | boolean
  | number
  | string
  | AutoPayloadValue[]
  | { [key: string]: AutoPayloadValue };

export interface AutoPayload {
  [key: string]: AutoPayloadValue;
}

export interface PluginVersionResult {
  /**
   * Version identifier returned by the platform implementation.
   */
  version: string;
}

export interface AutoAvailability {
  /**
   * Whether the current platform ships a native car integration.
   */
  available: boolean;

  /**
   * Whether a car host is currently connected to this app.
   */
  connected: boolean;

  /**
   * Platform that answered the request.
   */
  platform: AutoPlatform;
}

export interface AutoTemplateItem {
  /**
   * Stable action id sent back in the `carAction` event when the row is selected.
   */
  id: string;

  /**
   * Primary row text.
   */
  title: string;

  /**
   * Optional secondary row text.
   */
  subtitle?: string;

  /**
   * Optional value returned with the `carAction` event.
   */
  payload?: AutoPayload;

  /**
   * Whether the row can be selected.
   *
   * @default true
   */
  enabled?: boolean;
}

export interface AutoTemplateSection {
  /**
   * Optional section title. Supported by CarPlay; Android Auto currently flattens sections.
   */
  header?: string;

  /**
   * Rows to render in this section.
   */
  items: AutoTemplateItem[];
}

export interface AutoTemplateOptions {
  /**
   * Title shown at the top of the car template.
   */
  title: string;

  /**
   * Sections and rows to show in the car UI.
   */
  sections: AutoTemplateSection[];

  /**
   * Text shown when there are no rows.
   */
  emptyText?: string;
}

export interface AutoMessageOptions {
  /**
   * Application-defined message type.
   */
  type: string;

  /**
   * Optional application-defined payload.
   */
  payload?: AutoPayload;
}

export interface AutoConnectionChangedEvent {
  connected: boolean;
  platform: AutoPlatform;
}

export interface AutoActionEvent {
  id: string;
  title?: string;
  payload?: AutoPayload;
  platform: AutoPlatform;
}

export interface AutoMessageEvent {
  type: string;
  payload?: AutoPayload;
  platform: AutoPlatform;
}

export interface AutoPlugin {
  /**
   * Returns whether the current platform supports this plugin and whether a car is connected.
   */
  isAvailable(): Promise<AutoAvailability>;

  /**
   * Sets the root car template. Use this to push phone app state to the car display.
   */
  setRootTemplate(options: AutoTemplateOptions): Promise<void>;

  /**
   * Sends an application-defined message to the native car bridge.
   */
  sendMessage(options: AutoMessageOptions): Promise<void>;

  /**
   * Returns the platform implementation version marker.
   */
  getPluginVersion(): Promise<PluginVersionResult>;

  /**
   * Fired when the car host connects or disconnects.
   */
  addListener(
    eventName: 'connectionChanged',
    listenerFunc: (event: AutoConnectionChangedEvent) => void,
  ): Promise<PluginListenerHandle>;

  /**
   * Fired when the user selects an action row in the car UI.
   */
  addListener(eventName: 'carAction', listenerFunc: (event: AutoActionEvent) => void): Promise<PluginListenerHandle>;

  /**
   * Fired for application-defined native car bridge messages.
   */
  addListener(
    eventName: 'messageReceived',
    listenerFunc: (event: AutoMessageEvent) => void,
  ): Promise<PluginListenerHandle>;

  removeAllListeners(): Promise<void>;
}
